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

        /// <summary>
        /// Enforces the student-only session guard, then loads the dashboard's data
        /// (task list, urgent tasks, sidebar, bottom cards) on first load.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
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

        /// <summary>
        /// Orchestrates loading of every dashboard section for the given student:
        /// the full task list, the pending/total counters, urgent tasks, sidebar
        /// classes, and the bottom summary cards.
        /// </summary>
        /// <param name="studentID">The logged-in student's UserID.</param>
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

        /// <summary>
        /// Loads all tasks across all classes the student is enrolled in, together
        /// with each task's completion status for this student.
        /// </summary>
        /// <param name="studentID">The logged-in student's UserID.</param>
        /// <param name="connStr">The database connection string.</param>
        /// <returns>A DataTable of tasks with class name and completion status.</returns>
        // ORDER BY sorts on MarkedComplete first so pending tasks always come before
        // completed ones, then DueDate ascending and PriorityLevel descending within each
        // group. This mirrors the default "due" sort in the page's client-side JS
        // (applyFilters in StudentDashboard.aspx) so a completed task is never ranked
        // ahead of a pending one purely because it is due sooner or marked higher priority.
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
                    "ORDER BY ISNULL(cr.MarkedComplete, 0) ASC, ht.DueDate ASC, ht.PriorityLevel DESC";

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

        /// <summary>
        /// Loads at most 2 urgent tasks due within 2 days that are still pending,
        /// and shows the urgent panel if any are found.
        /// </summary>
        /// <param name="studentID">The logged-in student's UserID.</param>
        /// <param name="connStr">The database connection string.</param>
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

        /// <summary>
        /// Loads the sidebar class list with pending count and overdue count per class.
        /// </summary>
        /// <param name="studentID">The logged-in student's UserID.</param>
        /// <param name="connStr">The database connection string.</param>
        // OverdueCount drives the orange badge colour, if any pending task is overdue,
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

        /// <summary>
        /// Builds the My Classes and Completion Progress bottom cards by grouping the
        /// already-loaded tasks DataTable by class in C#, avoiding a second database query.
        /// </summary>
        /// <param name="allTasks">The full task DataTable already loaded by LoadAllTasks.</param>
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

        /// <summary>
        /// Logs the student out and redirects to the login page.
        /// </summary>
        /// <param name="sender">The logout button raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        /// <summary>
        /// Builds the one or two letter initials shown in the avatar badge from the
        /// logged-in student's full name.
        /// </summary>
        /// <returns>The student's initials in uppercase, or "?" if no name is available.</returns>
        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        /// <summary>
        /// Renders the priority badge markup for a task's PriorityLevel value.
        /// </summary>
        /// <param name="priorityObj">The PriorityLevel column value (1, 2, or 3).</param>
        /// <returns>HTML markup for the matching priority badge.</returns>
        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        /// <summary>
        /// Renders the completion status badge markup for a task.
        /// </summary>
        /// <param name="markedCompleteObj">The MarkedComplete column value.</param>
        /// <returns>HTML markup for the Complete or Pending badge.</returns>
        protected string GetStatusBadge(object markedCompleteObj)
        {
            return Convert.ToBoolean(markedCompleteObj)
                ? "<span class=\"badge badge-complete\">Complete</span>"
                : "<span class=\"badge badge-pending\">Pending</span>";
        }

        /// <summary>
        /// Converts a task's due date into a human-readable urgency string relative to today.
        /// </summary>
        /// <param name="dueDateObj">The DueDate column value.</param>
        /// <returns>A string such as "Overdue", "Due today", "Tomorrow", or "In N days".</returns>
        protected string GetUrgencyText(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0) return "Overdue";
            if (days == 0) return "Due today";
            if (days == 1) return "Tomorrow";
            return "In " + days + " days";
        }

        /// <summary>
        /// Chooses the CSS class that colours a due date badge based on how soon it falls.
        /// </summary>
        /// <param name="dueDateObj">The DueDate column value.</param>
        /// <returns>"due-red", "due-orange", or "due-green" depending on urgency.</returns>
        protected string GetUrgencyClass(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0 || days <= 1) return "due-red";
            if (days <= 4) return "due-orange";
            return "due-green";
        }
    }
}