using System;
using System.Collections.Generic;
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

        // - Page lifecycle -

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

        // Loads sidebar with pending count and overdue count per class.
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

        // Loads all tasks for the class with this student's completion status.
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
                    "ORDER BY ht.DueDate ASC, ht.PriorityLevel DESC";

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
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        protected string GetNavClass(object classIDObj)
        {
            return Convert.ToInt32(classIDObj) == _currentClassID ? "nav-item active" : "nav-item";
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