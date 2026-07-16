using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the Mark Completions page.
    // Three-step workflow: select class, select task, mark or unmark students.
    // State is maintained in ViewState between postbacks.
    public partial class MarkCompletions : Page
    {
        // - Properties -

        // Currently selected class ID, stored in ViewState
        public int SelectedClassID
        {
            get { return ViewState["SelectedClassID"] != null ? Convert.ToInt32(ViewState["SelectedClassID"]) : 0; }
            set { ViewState["SelectedClassID"] = value; }
        }

        // Currently selected task ID, stored in ViewState
        public int SelectedTaskID
        {
            get { return ViewState["SelectedTaskID"] != null ? Convert.ToInt32(ViewState["SelectedTaskID"]) : 0; }
            set { ViewState["SelectedTaskID"] = value; }
        }

        // Completion percentage for the progress bar
        public double CompletionPct { get; set; }

        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> sidebarClasses = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = sidebarClasses;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                LoadClassSelector(teacherID);
            }
            else
            {
                // On postback, rebind all panels from current ViewState
                LoadClassSelector(teacherID);
                if (SelectedClassID > 0) LoadTaskSelector(SelectedClassID);
                if (SelectedTaskID > 0) LoadStudentCompletions(SelectedTaskID);
            }
        }

        // - Methods -

        // Loads the class selector grid with student and task counts.
        private void LoadClassSelector(int teacherID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT c.ClassID, c.ClassName, " +
                    "(SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = c.ClassID) AS StudentCount, " +
                    "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = c.ClassID) AS TaskCount " +
                    "FROM Classes c WHERE c.TeacherID = @TeacherID ORDER BY c.ClassName";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            rptClasses.DataSource = dt;
            rptClasses.DataBind();

            if (SelectedClassID > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    if (Convert.ToInt32(row["ClassID"]) == SelectedClassID)
                    {
                        lblSelectedClass.Text = "Selected: " + row["ClassName"].ToString();
                        break;
                    }
                }
            }
        }

        // Loads the task table for the selected class.
        private void LoadTaskSelector(int classID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();
            int totalStudents = 0;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                using (SqlCommand cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = @ClassID", conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    totalStudents = Convert.ToInt32(cmd.ExecuteScalar());
                }

                string sql =
                    "SELECT ht.TaskID, ht.Title, ht.Subject, ht.DueDate, ht.PriorityLevel, " +
                    "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS CompletionCount, " +
                    "@TotalStudents AS TotalStudents " +
                    "FROM HomeworkTasks ht " +
                    "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID " +
                    "WHERE ht.ClassID = @ClassID " +
                    "GROUP BY ht.TaskID, ht.Title, ht.Subject, ht.DueDate, ht.PriorityLevel " +
                    "ORDER BY ht.DueDate ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@TotalStudents", totalStudents);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }

            rptTasks.DataSource = dt;
            rptTasks.DataBind();
            pnlTaskSelector.Visible = true;
            pnlNoTasks.Visible = dt.Rows.Count == 0;

            if (SelectedTaskID > 0)
            {
                foreach (DataRow row in dt.Rows)
                {
                    if (Convert.ToInt32(row["TaskID"]) == SelectedTaskID)
                    {
                        lblSelectedTask.Text = "Selected: " + row["Title"].ToString();
                        break;
                    }
                }
            }
        }

        // Loads the student completion list for the selected task.
        private void LoadStudentCompletions(int taskID)
        {
            int classID = SelectedClassID;
            List<PaceUser> students = SchoolClass.GetEnrolledStudents(classID);

            if (students.Count == 0)
            {
                pnlStudents.Visible = true;
                pnlNoStudents.Visible = true;
                rptStudents.DataSource = null;
                rptStudents.DataBind();
                CompletionPct = 0;
                return;
            }

            DataTable dt = new DataTable();
            dt.Columns.Add("StudentID", typeof(int));
            dt.Columns.Add("FullName", typeof(string));
            dt.Columns.Add("MarkedComplete", typeof(bool));

            int completedCount = 0;
            foreach (PaceUser student in students)
            {
                bool done = CompletionRecord.IsComplete(taskID, student.UserID);
                if (done) completedCount++;
                dt.Rows.Add(student.UserID, student.FullName, done);
            }

            CompletionPct = students.Count > 0
                ? Math.Round((double)completedCount / students.Count * 100, 1) : 0;

            lblCompletionSummary.Text = completedCount + " of " + students.Count + " complete";

            rptStudents.DataSource = dt;
            rptStudents.DataBind();
            pnlStudents.Visible = true;
            pnlNoStudents.Visible = false;
        }

        protected void ClassCommand(object sender, CommandEventArgs e)
        {
            pnlSuccess.Visible = false;
            SelectedClassID = Convert.ToInt32(e.CommandArgument);
            SelectedTaskID = 0;
            pnlStudents.Visible = false;
        }

        protected void TaskCommand(object sender, CommandEventArgs e)
        {
            pnlSuccess.Visible = false;
            SelectedTaskID = Convert.ToInt32(e.CommandArgument);
        }

        protected void StudentCommand(object sender, CommandEventArgs e)
        {
            int studentID = Convert.ToInt32(e.CommandArgument);
            int taskID = SelectedTaskID;
            pnlSuccess.Visible = false;

            if (e.CommandName == "Mark")
            {
                bool ok = CompletionRecord.MarkComplete(taskID, studentID);
                if (ok) { lblSuccess.Text = "Student marked as complete."; pnlSuccess.Visible = true; }
            }
            else if (e.CommandName == "Unmark")
            {
                bool ok = CompletionRecord.UnmarkComplete(taskID, studentID);
                if (ok) { lblSuccess.Text = "Completion mark removed."; pnlSuccess.Visible = true; }
            }
        }

        // Returns the CSS class for each step.
        // Step 1: active until class chosen, then selected (not a done checkmark).
        // Step 2: inactive until class chosen, active until task chosen, then selected.
        // Step 3: inactive until task chosen, then active (currently marking).
        // A step is never shown as "done" with a checkmark - only as selected (highlighted)
        // or active (needs action now), keeping the state clear and non-misleading.
        public string GetStepClass(int stepNumber)
        {
            if (stepNumber == 1)
            {
                // Always show step 1 as selected once a class has been picked,
                // never as done, to make it easy to switch classes
                return SelectedClassID > 0 ? "selected" : "active";
            }
            if (stepNumber == 2)
            {
                if (SelectedClassID == 0) return "step"; // inactive, waiting for step 1
                return SelectedTaskID > 0 ? "selected" : "active";
            }
            if (stepNumber == 3)
            {
                // Step 3 stays active while marking is in progress
                return SelectedTaskID > 0 ? "active" : "step";
            }
            return "step";
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

        protected string GetStudentInitials(object nameObj)
        {
            string name = nameObj != null ? nameObj.ToString() : "?";
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
                ? "<span class=\"badge\" style=\"color:var(--green);background:var(--green-bg);border-color:var(--green-border);\"><i class='ti ti-check'></i> Complete</span>"
                : "<span class=\"badge\" style=\"color:var(--text-muted);background:var(--bg);border-color:var(--border);\">Pending</span>";
        }
    }
}