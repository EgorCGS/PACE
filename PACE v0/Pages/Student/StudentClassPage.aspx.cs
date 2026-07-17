using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the student per-class task page.
    // Loads all tasks for the class the student is enrolled in.
    // Sidebar includes pending and overdue counts per class for badge colouring.
    public partial class StudentClassPage : Page
    {
        private int _currentClassID = 0;

        // Class progress stats, computed once from the same DataTable LoadTasks already
        // fetches so the page does not issue a second round trip just to count rows.
        // Held as fields rather than DB-backed properties since they only need to survive
        // from LoadTasks to the markup's <%= %> calls within the same render pass.
        private int _statTotal = 0;
        private int _statCompleted = 0;
        private int _statPending = 0;
        private double _statPct = 0;

        // - Page lifecycle -

        /// <summary>
        /// Enforces the student-only session guard, resolves and validates the ClassID
        /// query string parameter, confirms the student is enrolled in that class, then
        /// loads the sidebar and task list on first load.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Student") { Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx"); return; }

            int studentID = Convert.ToInt32(Session["UserID"]);

            int classID = 0;
            if (!int.TryParse(Request.QueryString["ClassID"], out classID) || classID <= 0)
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            _currentClassID = classID;

            // Load sidebar with pending + overdue counts
            DataTable sidebarDt = LoadSidebarClasses(studentID);

            // Verify the student is enrolled in the requested class
            bool enrolled = false;
            string className = "";
            foreach (DataRow row in sidebarDt.Rows)
            {
                if (Convert.ToInt32(row["ClassID"]) == classID)
                {
                    enrolled = true;
                    className = row["ClassName"].ToString();
                    break;
                }
            }

            if (!enrolled)
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            rptSidebarClasses.DataSource = sidebarDt;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                lblHeroTitle.Text = className;
                lblBreadcrumb.Text = className;
                LoadTasks(classID, studentID);
            }
        }

        // - Methods -

        /// <summary>
        /// Loads the sidebar class list with pending count and overdue count per class.
        /// </summary>
        /// <param name="studentID">The logged-in student's UserID.</param>
        /// <returns>A DataTable of the student's enrolled classes with pending/overdue counts.</returns>
        // OverdueCount drives the orange badge on the sidebar nav items.
        private DataTable LoadSidebarClasses(int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
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

            return dt;
        }

        /// <summary>
        /// Loads all tasks for the class with this student's completion status, binds them
        /// to the repeater, and triggers the progress stat computation.
        /// </summary>
        /// <param name="classID">The class to load tasks for.</param>
        /// <param name="studentID">The logged-in student's UserID.</param>
        // ORDER BY sorts on MarkedComplete first so pending tasks always come before
        // completed ones, then DueDate ascending and PriorityLevel descending within each
        // group. This page has no client-side sort dropdown (unlike StudentDashboard), so
        // this ORDER BY is the only thing controlling row order, it mirrors the same
        // pending-before-completed rule applied to StudentDashboard.aspx.cs LoadAllTasks.
        private void LoadTasks(int classID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT ht.TaskID, ht.Title, ht.Description, " +
                    "ht.DueDate, ht.PriorityLevel, " +
                    "ISNULL(cr.MarkedComplete, 0) AS MarkedComplete " +
                    "FROM HomeworkTasks ht " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID AND cr.StudentID = @StudentID " +
                    "WHERE ht.ClassID = @ClassID " +
                    "ORDER BY ISNULL(cr.MarkedComplete, 0) ASC, ht.DueDate ASC, ht.PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            lblTaskCount.Text = dt.Rows.Count.ToString();
            rptTasks.DataSource = dt;
            rptTasks.DataBind();
            pnlNoTasks.Visible = dt.Rows.Count == 0;

            ComputeStats(dt);
        }

        /// <summary>
        /// Computes the Class Progress card's total, completed, pending counts and
        /// completion percentage from the DataTable LoadTasks already fetched.
        /// </summary>
        /// <param name="dt">The class's task DataTable already loaded by LoadTasks.</param>
        // so the stats add no extra query. A plain loop over
        // the DataTable is used, rather than a LINQ aggregate or a second SQL COUNT query,
        // since the row count per class is small and the data is already in memory.
        private void ComputeStats(DataTable dt)
        {
            _statTotal = dt.Rows.Count;
            _statCompleted = 0;
            foreach (DataRow row in dt.Rows)
                if (Convert.ToBoolean(row["MarkedComplete"])) _statCompleted++;

            _statPending = _statTotal - _statCompleted;
            _statPct = _statTotal > 0 ? Math.Round((double)_statCompleted / _statTotal * 100, 0) : 0;

            lblStatTotal.Text = _statTotal.ToString();
            lblStatCompleted.Text = _statCompleted.ToString();
            lblStatPending.Text = _statPending.ToString();
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
        /// Chooses the CSS class for a sidebar nav item, marking it active if it matches
        /// the class currently being viewed.
        /// </summary>
        /// <param name="classIDObj">The ClassID column value for the sidebar row.</param>
        /// <returns>"nav-item active" if this is the current class, otherwise "nav-item".</returns>
        protected string GetNavClass(object classIDObj)
        {
            return Convert.ToInt32(classIDObj) == _currentClassID ? "nav-item active" : "nav-item";
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

        // - Class progress stats rendering -
        // Read directly by <%= %> expressions in the markup, called after ComputeStats
        // has already populated the fields during Page_Load, same pattern StudentDashboard
        // uses for its Completion Progress bars but as single values instead of a Repeater
        // since this page only ever shows one class's progress at a time.

        /// <summary>
        /// Formats the class completion percentage for display.
        /// </summary>
        /// <returns>The completion percentage as a whole-number string with a trailing "%".</returns>
        protected string GetStatsPctDisplay()
        {
            return _statPct.ToString("0") + "%";
        }

        /// <summary>
        /// Formats the class completion percentage for use as a progress bar width.
        /// </summary>
        /// <returns>The completion percentage capped at 100, as a whole-number string.</returns>
        protected string GetStatsPctWidth()
        {
            return Math.Min(_statPct, 100).ToString("0");
        }

        /// <summary>
        /// Chooses the CSS class that colours the class progress bar based on completion percentage.
        /// </summary>
        /// <returns>"green" at 70% or above, "orange" at 40% or above, "zero" at 0%, otherwise empty.</returns>
        protected string GetStatsPctClass()
        {
            if (_statPct >= 70) return "green";
            if (_statPct >= 40) return "orange";
            if (_statPct == 0) return "zero";
            return "";
        }
    }
}