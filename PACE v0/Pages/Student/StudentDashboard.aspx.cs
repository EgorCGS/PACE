using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the student main dashboard.
    // Loads all homework tasks assigned to the logged-in student,
    // ordered by due date then priority, and binds them to the task table.
    public partial class StudentDashboard : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            // Redirect to login if no session exists
            if (Session["Role"] == null)
            {
                Response.Redirect("~/Login.aspx");
                return;
            }

            // Redirect teachers away from the student page
            if (Session["Role"].ToString() != "Student")
            {
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            if (!IsPostBack)
            {
                // Set the hero greeting name
                lblHeroName.Text = Session["FullName"].ToString();

                // Load the sidebar class list using SchoolClass.GetClassesByStudent()
                int studentID = Convert.ToInt32(Session["UserID"]);
                List<SchoolClass> classes = SchoolClass.GetClassesByStudent(studentID);
                rptSidebarClasses.DataSource = classes;
                rptSidebarClasses.DataBind();

                // Load all tasks for this student from the database
                LoadTasks(studentID);
            }
        }

        // - Methods -

        // Queries all homework tasks across all classes the student is enrolled in,
        // joined with completion status. Orders by due date then priority (highest first).
        private void LoadTasks(int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Single JOIN query covering all enrolled classes and completion status.
                // ISNULL handles tasks with no completion record yet (treated as not complete).
                string sql = "SELECT ht.TaskID, ht.Title, ht.Subject, ht.Description, " +
                             "ht.DueDate, ht.PriorityLevel, c.ClassName, " +
                             "ISNULL(cr.MarkedComplete, 0) AS MarkedComplete " +
                             "FROM HomeworkTasks ht " +
                             "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                             "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID " +
                             "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID " +
                             "  AND cr.StudentID = @StudentID " +
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

            // Count pending tasks for the hero subtitle
            int pending = 0;
            foreach (DataRow row in dt.Rows)
            {
                if (!Convert.ToBoolean(row["MarkedComplete"])) pending++;
            }

            lblPendingCount.Text = pending.ToString();
            lblTaskCount.Text = dt.Rows.Count.ToString();

            rptTasks.DataSource = dt;
            rptTasks.DataBind();

            // Show the empty state message if there are no tasks
            pnlNoTasks.Visible = dt.Rows.Count == 0;
        }

        // Handles the logout button click in the sidebar.
        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        // Returns the logged-in student's initials for the sidebar avatar.
        // Called directly from the ASPX using <%= %>.
        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        // Returns the HTML badge for a task's priority level.
        // Called from the Repeater ItemTemplate using <%# %>.
        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        // Returns the HTML badge for a task's completion status.
        protected string GetStatusBadge(object markedCompleteObj)
        {
            bool complete = Convert.ToBoolean(markedCompleteObj);
            return complete
                ? "<span class=\"badge badge-complete\">Complete</span>"
                : "<span class=\"badge badge-pending\">Pending</span>";
        }

        // Returns a human-readable urgency label based on how many days until due.
        protected string GetUrgencyText(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0) return "Overdue";
            if (days == 0) return "Due today";
            if (days == 1) return "Tomorrow";
            return "In " + days + " days";
        }

        // Returns the CSS class for the urgency label colour.
        protected string GetUrgencyClass(object dueDateObj)
        {
            int days = (Convert.ToDateTime(dueDateObj).Date - DateTime.Today).Days;
            if (days < 0 || days <= 1) return "due-red";
            if (days <= 4) return "due-orange";
            return "due-green";
        }
    }
}