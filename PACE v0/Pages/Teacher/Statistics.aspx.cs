using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the teacher statistics page.
    // Generates class-wide task completion rates and per-student breakdowns.
    public partial class Statistics : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);

            // Sidebar always needs binding
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                ddlClass.DataSource = classes;
                ddlClass.DataTextField = "ClassName";
                ddlClass.DataValueField = "ClassID";
                ddlClass.DataBind();
                ddlClass.Items.Insert(0, new ListItem("-- Select a class --", "0"));
            }
        }

        // - Methods -

        // Fires when the teacher selects a class from the dropdown.
        protected void ddlClass_SelectedIndexChanged(object sender, EventArgs e)
        {
            int classID = Convert.ToInt32(ddlClass.SelectedValue);
            int teacherID = Convert.ToInt32(Session["UserID"]);

            if (classID == 0)
            {
                pnlStats.Visible = false;
                pnlHint.Visible = true;
                return;
            }

            // Security check: teacher must own the selected class
            if (!SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                pnlStats.Visible = false;
                pnlHint.Visible = true;
                return;
            }

            LoadStats(classID);
        }

        // Loads task and student statistics for the selected class.
        // Uses StatisticsReport.GenerateTaskStats() for task-level data,
        // and a direct query for student-level data to correctly include
        // students who have not yet completed any tasks.
        private void LoadStats(int classID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            // Task stats via StatisticsReport class
            StatisticsReport report = new StatisticsReport();
            report.TotalStudents = GetEnrolledCount(classID, connStr);
            DataTable taskStats = report.GenerateTaskStats(classID);

            // Student stats via a direct query.
            // Using LEFT JOIN throughout so students with zero completions still appear.
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

            // Compute summary numbers
            int totalTasks = taskStats.Rows.Count;
            int totalStudents = report.TotalStudents;

            // Overall completion rate: total completions across all tasks / max possible completions
            double overallPct = 0;
            if (totalTasks > 0 && totalStudents > 0)
            {
                double totalCompletions = 0;
                foreach (DataRow row in taskStats.Rows)
                    totalCompletions += Convert.ToInt32(row["CompletionCount"]);

                overallPct = Math.Round(totalCompletions / (totalTasks * totalStudents) * 100, 1);
            }

            lblTotalStudents.Text = totalStudents.ToString();
            lblTotalTasks.Text = totalTasks.ToString();
            lblOverallPct.Text = overallPct + "%";

            // Bind task stats repeater
            rptTaskStats.DataSource = taskStats;
            rptTaskStats.DataBind();
            pnlNoTasks.Visible = taskStats.Rows.Count == 0;

            // Bind student stats repeater
            rptStudentStats.DataSource = studentStats;
            rptStudentStats.DataBind();
            pnlNoStudents.Visible = studentStats.Rows.Count == 0;

            pnlStats.Visible = true;
            pnlHint.Visible = false;
        }

        // Gets the total number of students enrolled in a class.
        private int GetEnrolledCount(int classID, string connStr)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = @ClassID", conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
        }

        // Returns the CSS class for the progress bar fill colour.
        // Green for high completion, orange for medium, red-ish (default) for low.
        protected string GetPctClass(object pctObj)
        {
            double pct = Convert.ToDouble(pctObj);
            if (pct >= 70) return "green";
            if (pct >= 40) return "orange";
            if (pct == 0) return "zero";
            return "";
        }

        // Calculates and returns the percentage string for a student row.
        protected string GetStudentPct(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return "0";
            return Math.Round((double)completed / total * 100, 0).ToString();
        }

        // Returns the raw double percentage for colour class calculation.
        protected double GetStudentPctRaw(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return 0;
            return Math.Round((double)completed / total * 100, 1);
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }
    }
}