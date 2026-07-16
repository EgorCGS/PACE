using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the student main dashboard.
    // Loads all tasks, urgent tasks, sidebar classes with overdue detection,
    // and bottom card data.
    public partial class StudentDashboard : Page
    {
        private static readonly string[] DotColors = {
            "#4a6fa5", "#3a9e6e", "#d4882a", "#6b3db0", "#d95c5c", "#1a7f8e"
        };

        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Student") { Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx"); return; }

            if (!IsPostBack)
            {
                int studentID = Convert.ToInt32(Session["UserID"]);
                lblHeroName.Text = Session["FullName"].ToString();
                LoadAll(studentID);
            }
        }

        // - Methods -

        private void LoadAll(int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable allTasks = LoadAllTasks(studentID, connStr);

            int pending = 0;
            foreach (DataRow row in allTasks.Rows)
                if (!Convert.ToBoolean(row["MarkedComplete"])) pending++;

            lblPendingCount.Text = pending.ToString();
            lblTaskCount.Text = allTasks.Rows.Count.ToString();

            rptTasks.DataSource = allTasks;
            rptTasks.DataBind();
            pnlNoTasks.Visible = allTasks.Rows.Count == 0;

            LoadUrgentTasks(studentID, connStr);
            LoadSidebarClasses(studentID, connStr);
            BuildBottomCards(allTasks);
        }

        // Loads all tasks across all enrolled classes with completion status.
        private DataTable LoadAllTasks(int studentID, string connStr)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT ht.TaskID, ht.ClassID, ht.Title, ht.Subject, ht.Description, " +
                    "ht.DueDate, ht.PriorityLevel, c.ClassName, " +
                    "ISNULL(cr.MarkedComplete, 0) AS MarkedComplete " +
                    "FROM HomeworkTasks ht " +
                    "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                    "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID AND cr.StudentID = @StudentID " +
                    "WHERE ce.StudentID = @StudentID " +
                    "ORDER BY ht.DueDate ASC, ht.PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@StudentID", studentID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        // Loads at most 2 urgent tasks due within 2 days that are still pending.
        private void LoadUrgentTasks(int studentID, string connStr)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT TOP 2 ht.TaskID, ht.Title, ht.Subject, ht.DueDate, ht.PriorityLevel " +
                    "FROM HomeworkTasks ht " +
                    "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                    "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID AND cr.StudentID = @StudentID " +
                    "WHERE ce.StudentID = @StudentID " +
                    "AND ht.DueDate <= DATEADD(day, 2, CAST(GETDATE() AS DATE)) " +
                    "AND ISNULL(cr.MarkedComplete, 0) = 0 " +
                    "ORDER BY ht.DueDate ASC, ht.PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@StudentID", studentID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            if (dt.Rows.Count > 0)
            {
                rptUrgent.DataSource = dt;
                rptUrgent.DataBind();
                pnlUrgent.Visible = true;
            }
        }

        // Loads the sidebar class list with pending count AND overdue count per class.
        // OverdueCount drives the orange badge colour — if any pending task is overdue,
        // the badge turns orange to signal urgency rather than just quantity.
        private void LoadSidebarClasses(int studentID, string connStr)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT c.ClassID, c.ClassName, " +
                    "COUNT(CASE WHEN ht.TaskID IS NOT NULL AND ISNULL(cr.MarkedComplete, 0) = 0 THEN 1 END) AS PendingCount, " +
                    "COUNT(CASE WHEN ht.TaskID IS NOT NULL AND ISNULL(cr.MarkedComplete, 0) = 0 " +
                    "           AND ht.DueDate < CAST(GETDATE() AS DATE) THEN 1 END) AS OverdueCount " +
                    "FROM Classes c " +
                    "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID AND ce.StudentID = @StudentID " +
                    "LEFT JOIN HomeworkTasks ht ON ht.ClassID = c.ClassID " +
                    "LEFT JOIN CompletionRecords cr ON cr.TaskID = ht.TaskID AND cr.StudentID = @StudentID " +
                    "GROUP BY c.ClassID, c.ClassName " +
                    "ORDER BY c.ClassName";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@StudentID", studentID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            rptSidebarClasses.DataSource = dt;
            rptSidebarClasses.DataBind();
        }

        // Builds the My Classes and Completion Progress bottom cards
        // by grouping the already-loaded tasks DataTable by class in C#.
        private void BuildBottomCards(DataTable allTasks)
        {
            Dictionary<int, object[]> classMap = new Dictionary<int, object[]>();

            foreach (DataRow row in allTasks.Rows)
            {
                int classID = Convert.ToInt32(row["ClassID"]);
                string cname = row["ClassName"].ToString();
                bool complete = Convert.ToBoolean(row["MarkedComplete"]);

                if (!classMap.ContainsKey(classID))
                    classMap[classID] = new object[] { cname, 0, 0, 0 };

                classMap[classID][2] = Convert.ToInt32(classMap[classID][2]) + 1;
                if (!complete) classMap[classID][1] = Convert.ToInt32(classMap[classID][1]) + 1;
                else classMap[classID][3] = Convert.ToInt32(classMap[classID][3]) + 1;
            }

            DataTable bottomDt = new DataTable();
            bottomDt.Columns.Add("ClassID", typeof(int));
            bottomDt.Columns.Add("ClassName", typeof(string));
            bottomDt.Columns.Add("PendingCount", typeof(int));
            bottomDt.Columns.Add("DotColor", typeof(string));
            bottomDt.Columns.Add("PctDisplay", typeof(string));
            bottomDt.Columns.Add("PctClass", typeof(string));
            bottomDt.Columns.Add("PctWidth", typeof(string));

            int colorIndex = 0;
            foreach (var kvp in classMap)
            {
                int total = Convert.ToInt32(kvp.Value[2]);
                int completed = Convert.ToInt32(kvp.Value[3]);
                int pending = Convert.ToInt32(kvp.Value[1]);
                double pct = total > 0 ? Math.Round((double)completed / total * 100, 0) : 0;
                string pctClass = pct >= 70 ? "green" : pct >= 40 ? "orange" : pct == 0 ? "zero" : "";

                bottomDt.Rows.Add(
                    kvp.Key,
                    kvp.Value[0].ToString(),
                    pending,
                    DotColors[colorIndex % DotColors.Length],
                    pct.ToString("0") + "%",
                    pctClass,
                    Math.Min(pct, 100).ToString("0")
                );
                colorIndex++;
            }

            rptBottomClasses.DataSource = bottomDt;
            rptBottomClasses.DataBind();
            rptProgress.DataSource = bottomDt;
            rptProgress.DataBind();
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

        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        protected string GetStatusBadge(object markedCompleteObj)
        {
            return Convert.ToBoolean(markedCompleteObj)
                ? "<span class=\"badge badge-complete\">Complete</span>"
                : "<span class=\"badge badge-pending\">Pending</span>";
        }

        protected string GetUrgencyText(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0) return "Overdue";
            if (days == 0) return "Due today";
            if (days == 1) return "Tomorrow";
            return "In " + days + " days";
        }

        protected string GetUrgencyClass(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0 || days <= 1) return "due-red";
            if (days <= 4) return "due-orange";
            return "due-green";
        }
    }
}