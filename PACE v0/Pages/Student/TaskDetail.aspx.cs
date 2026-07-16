using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the student task detail page.
    // Reads TaskID from the query string and loads full task details.
    // No hero on this page - uses compact subheader instead.
    public partial class TaskDetail : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Student") { Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx"); return; }

            int studentID = Convert.ToInt32(Session["UserID"]);

            // Load sidebar with pending and overdue counts
            DataTable sidebarDt = LoadSidebarClasses(studentID);
            rptSidebarClasses.DataSource = sidebarDt;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                int taskID = 0;
                if (!int.TryParse(Request.QueryString["TaskID"], out taskID) || taskID <= 0)
                {
                    pnlNotFound.Visible = true;
                    return;
                }

                LoadTask(taskID, studentID);
            }
        }

        // - Methods -

        // Loads sidebar class list with pending and overdue counts per class.
        // OverdueCount drives the orange badge colour on the sidebar nav items.
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

        // Loads the task and verifies the student is enrolled in the task's class.
        // If the student is not enrolled, the not-found panel is shown instead.
        private void LoadTask(int taskID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql =
                    "SELECT ht.Title, ht.Subject, ht.Description, ht.DueDate, " +
                    "ht.PriorityLevel, c.ClassName, " +
                    "ISNULL(cr.MarkedComplete, 0) AS MarkedComplete " +
                    "FROM HomeworkTasks ht " +
                    "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                    "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID AND ce.StudentID = @StudentID " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID AND cr.StudentID = @StudentID " +
                    "WHERE ht.TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            lblTitle.Text = reader["Title"].ToString();
                            lblSubject.Text = reader["Subject"].ToString();
                            lblClass.Text = reader["ClassName"].ToString();
                            lblDescription.Text = reader["Description"].ToString();
                            lblDueDate.Text = Convert.ToDateTime(reader["DueDate"]).ToString("dddd, d MMMM yyyy");

                            int priority = Convert.ToInt32(reader["PriorityLevel"]);
                            bool complete = Convert.ToBoolean(reader["MarkedComplete"]);

                            lblPriorityBadge.Text = GetPriorityBadge(priority);
                            lblStatusBadge.Text = complete
                                ? "<span class=\"badge badge-complete\"><i class=\"ti ti-check\"></i> Complete</span>"
                                : "<span class=\"badge badge-pending\">Pending</span>";

                            pnlTask.Visible = true;
                        }
                        else
                        {
                            pnlNotFound.Visible = true;
                        }
                    }
                }
            }
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

        private string GetPriorityBadge(int priority)
        {
            if (priority == 3) return "<span class=\"badge badge-high\"><i class=\"ti ti-arrow-up\"></i> High</span>";
            if (priority == 2) return "<span class=\"badge badge-med\"><i class=\"ti ti-minus\"></i> Medium</span>";
            return "<span class=\"badge badge-low\"><i class=\"ti ti-arrow-down\"></i> Low</span>";
        }
    }
}