using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the teacher per-class overview page.
    // Shows completion statistics by task and by student for the selected class.
    // Accessed by clicking a class name in the teacher sidebar.
    public partial class TeacherClassPage : Page
    {
        // Stores the current class ID so the sidebar can highlight the active class
        private int _currentClassID = 0;

        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);

            // Read ClassID from the URL query string
            int classID = 0;
            if (!int.TryParse(Request.QueryString["ClassID"], out classID) || classID <= 0)
            {
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            // Verify this teacher owns the class before showing anything
            if (!SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            _currentClassID = classID;

            // Load sidebar classes and bind, highlighting the active class
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                // Find the class name for the hero and breadcrumb
                string className = "";
                foreach (SchoolClass sc in classes)
                {
                    if (sc.ClassID == classID) { className = sc.ClassName; break; }
                }

                lblHeroTitle.Text = className;
                lblBreadcrumb.Text = className;

                LoadStats(classID);
            }
        }

        // - Methods -

        // Loads task-level and student-level statistics for the selected class.
        private void LoadStats(int classID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            // Get enrolled student count for the report
            int enrolledCount = 0;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = @ClassID", conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    enrolledCount = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }

            // Generate task-level stats using StatisticsReport.GenerateTaskStats()
            StatisticsReport report = new StatisticsReport();
            report.TotalStudents = enrolledCount;
            DataTable taskStats = report.GenerateTaskStats(classID);

            // Generate student-level stats with a direct query.
            // LEFT JOINs ensure students with zero completions still appear.
            DataTable studentStats = new DataTable();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT u.UserID, u.FullName, " +
                             "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS TasksCompleted, " +
                             "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = @ClassID) AS TotalTasks " +
                             "FROM Users u " +
                             "INNER JOIN ClassEnrolments ce ON u.UserID = ce.StudentID AND ce.ClassID = @ClassID " +
                             "LEFT JOIN CompletionRecords cr ON u.UserID = cr.StudentID " +
                             "LEFT JOIN HomeworkTasks ht ON cr.TaskID = ht.TaskID AND ht.ClassID = @ClassID " +
                             "GROUP BY u.UserID, u.FullName " +
                             "ORDER BY u.FullName ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(studentStats);
                    }
                }
            }

            // Compute overall completion percentage across all tasks and students
            double overallPct = 0;
            int totalTasks = taskStats.Rows.Count;
            if (totalTasks > 0 && enrolledCount > 0)
            {
                double totalCompletions = 0;
                foreach (DataRow row in taskStats.Rows)
                    totalCompletions += Convert.ToInt32(row["CompletionCount"]);
                overallPct = Math.Round(totalCompletions / (totalTasks * enrolledCount) * 100, 1);
            }

            lblTotalStudents.Text = enrolledCount.ToString();
            lblTotalTasks.Text = totalTasks.ToString();
            lblOverallPct.Text = overallPct + "%";

            rptTaskStats.DataSource = taskStats;
            rptTaskStats.DataBind();
            pnlNoTasks.Visible = taskStats.Rows.Count == 0;

            rptStudentStats.DataSource = studentStats;
            rptStudentStats.DataBind();
            pnlNoStudents.Visible = studentStats.Rows.Count == 0;
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        // Returns "nav-item active" for the current class, "nav-item" for all others.
        protected string GetNavClass(object classIDObj)
        {
            return Convert.ToInt32(classIDObj) == _currentClassID
                ? "nav-item active"
                : "nav-item";
        }

        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        // Returns initials for the student avatar in the student stats table.
        protected string GetStudentInitials(object nameObj)
        {
            string name = nameObj != null ? nameObj.ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        protected string GetPctClass(object pctObj)
        {
            double pct = Convert.ToDouble(pctObj);
            if (pct == 0) return "zero";
            if (pct >= 70) return "green";
            if (pct >= 40) return "orange";
            return "";
        }

        protected string GetStudentPct(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return "0";
            return Math.Round((double)completed / total * 100, 0).ToString();
        }

        protected double GetStudentPctRaw(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return 0;
            return Math.Round((double)completed / total * 100, 1);
        }
    }
}