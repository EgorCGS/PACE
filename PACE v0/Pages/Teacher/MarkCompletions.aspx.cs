using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the teacher completion marking page.
    // Teachers select a class and task, then mark or unmark individual students.
    public partial class MarkCompletions : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);

            // Sidebar binding always runs
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                // Populate class dropdown on first load
                ddlClass.DataSource = classes;
                ddlClass.DataTextField = "ClassName";
                ddlClass.DataValueField = "ClassID";
                ddlClass.DataBind();
                ddlClass.Items.Insert(0, new ListItem("-- Select a class --", "0"));

                ddlTask.Items.Clear();
                ddlTask.Items.Add(new ListItem("-- Select a task --", "0"));
            }
        }

        // - Methods -

        // Fires when the teacher changes the class dropdown.
        // Loads the tasks for the selected class into the task dropdown.
        protected void ddlClass_SelectedIndexChanged(object sender, EventArgs e)
        {
            pnlSuccess.Visible = false;
            ddlTask.Items.Clear();
            ddlTask.Items.Add(new ListItem("-- Select a task --", "0"));
            pnlStudents.Visible = false;
            pnlHint.Visible = true;
            lblCompletionSummary.Text = "";

            int classID = Convert.ToInt32(ddlClass.SelectedValue);
            if (classID == 0) return;

            // Load tasks for this class using a direct query
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "SELECT TaskID, Title FROM HomeworkTasks " +
                             "WHERE ClassID = @ClassID ORDER BY DueDate ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            ddlTask.Items.Add(new ListItem(
                                reader["Title"].ToString(),
                                reader["TaskID"].ToString()));
                        }
                    }
                }
            }
        }

        // Fires when the teacher changes the task dropdown.
        // Loads all enrolled students with their completion status for the selected task.
        protected void ddlTask_SelectedIndexChanged(object sender, EventArgs e)
        {
            pnlSuccess.Visible = false;
            int taskID = Convert.ToInt32(ddlTask.SelectedValue);
            if (taskID == 0)
            {
                pnlStudents.Visible = false;
                pnlHint.Visible = true;
                return;
            }

            LoadStudentCompletions(taskID);
        }

        // Loads the student completion list for a specific task.
        // Calls SchoolClass.GetEnrolledStudents() then checks completion per student.
        private void LoadStudentCompletions(int taskID)
        {
            int classID = Convert.ToInt32(ddlClass.SelectedValue);

            // Use SchoolClass.GetEnrolledStudents() to get the enrolled student list
            List<PaceUser> students = SchoolClass.GetEnrolledStudents(classID);

            if (students.Count == 0)
            {
                pnlStudents.Visible = true;
                pnlNoStudents.Visible = true;
                pnlHint.Visible = false;
                rptStudents.DataSource = null;
                rptStudents.DataBind();
                return;
            }

            // Build a DataTable combining student info with completion status.
            // Using CompletionRecord.IsComplete() for each student to check their status.
            DataTable dt = new DataTable();
            dt.Columns.Add("StudentID", typeof(int));
            dt.Columns.Add("FullName", typeof(string));
            dt.Columns.Add("MarkedComplete", typeof(bool));

            int completedCount = 0;
            foreach (PaceUser student in students)
            {
                bool isComplete = CompletionRecord.IsComplete(taskID, student.UserID);
                if (isComplete) completedCount++;
                dt.Rows.Add(student.UserID, student.FullName, isComplete);
            }

            lblCompletionSummary.Text = completedCount + " of " + students.Count + " complete";

            rptStudents.DataSource = dt;
            rptStudents.DataBind();
            pnlStudents.Visible = true;
            pnlNoStudents.Visible = false;
            pnlHint.Visible = false;
        }

        // Handles Mark and Unmark button clicks from the student Repeater.
        protected void StudentCommand(object sender, CommandEventArgs e)
        {
            int studentID = Convert.ToInt32(e.CommandArgument);
            int taskID = Convert.ToInt32(ddlTask.SelectedValue);

            if (e.CommandName == "Mark")
            {
                // Mark the student complete using CompletionRecord.MarkComplete()
                bool success = CompletionRecord.MarkComplete(taskID, studentID);
                if (success)
                {
                    lblSuccess.Text = "Student marked as complete.";
                    pnlSuccess.Visible = true;
                }
            }
            else if (e.CommandName == "Unmark")
            {
                // Unmark using CompletionRecord.UnmarkComplete()
                bool success = CompletionRecord.UnmarkComplete(taskID, studentID);
                if (success)
                {
                    lblSuccess.Text = "Completion mark removed.";
                    pnlSuccess.Visible = true;
                }
            }

            // Reload the student list to reflect the updated state
            LoadStudentCompletions(taskID);
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

        protected string GetStatusBadge(object markedCompleteObj)
        {
            bool complete = Convert.ToBoolean(markedCompleteObj);
            return complete
                ? "<span class=\"badge badge-complete\">Complete</span>"
                : "<span class=\"badge badge-pending\">Pending</span>";
        }
    }
}