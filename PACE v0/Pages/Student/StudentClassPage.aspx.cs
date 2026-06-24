using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the student per-class task page.
    // Shows all tasks for a specific class the student is enrolled in,
    // read from the ClassID query string parameter.
    public partial class StudentClassPage : Page
    {
        // Stores the current class ID so the sidebar helper can highlight the active link
        private int _currentClassID = 0;

        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Student") { Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx"); return; }

            int studentID = Convert.ToInt32(Session["UserID"]);

            // Read ClassID from the URL (e.g. StudentClassPage.aspx?ClassID=1)
            int classID = 0;
            if (!int.TryParse(Request.QueryString["ClassID"], out classID) || classID <= 0)
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            _currentClassID = classID;

            // Load the student's enrolled classes for the sidebar
            List<SchoolClass> classes = SchoolClass.GetClassesByStudent(studentID);

            // Confirm the student is actually enrolled in the requested class
            bool enrolled = false;
            string className = "";
            foreach (SchoolClass sc in classes)
            {
                if (sc.ClassID == classID)
                {
                    enrolled = true;
                    className = sc.ClassName;
                    break;
                }
            }

            // Redirect if the student is not enrolled (prevents URL-guessing access)
            if (!enrolled)
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            // Bind sidebar after confirming the class exists
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                lblHeroTitle.Text = className;
                lblBreadcrumb.Text = className;

                LoadTasks(classID, studentID);
            }
        }

        // - Methods -

        // Loads all tasks for this class with the student's completion status.
        // Uses the same JOIN pattern as the student dashboard but filtered to one class.
        private void LoadTasks(int classID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT ht.TaskID, ht.Title, ht.Description, " +
                             "ht.DueDate, ht.PriorityLevel, " +
                             "ISNULL(cr.MarkedComplete, 0) AS MarkedComplete " +
                             "FROM HomeworkTasks ht " +
                             "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID " +
                             "  AND cr.StudentID = @StudentID " +
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

        // Returns "nav-item active" for the currently viewed class, "nav-item" for all others.
        // Called from the sidebar Repeater template using <%# %>.
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