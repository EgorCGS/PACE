using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the teacher task management page.
    // Allows teachers to edit and delete their own homework tasks.
    public partial class ManageTasks : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            // Sidebar always needs binding on every request
            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                LoadTasks();
            }
        }

        // - Methods -

        // Loads all tasks created by the logged-in teacher across all their classes.
        private void LoadTasks()
        {
            int teacherID = Convert.ToInt32(Session["UserID"]);
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Join HomeworkTasks to Classes so we can filter by teacher
                // and show the class name in the table
                string sql = "SELECT ht.TaskID, ht.Title, ht.Subject, ht.DueDate, " +
                             "ht.PriorityLevel, c.ClassName, c.ClassID " +
                             "FROM HomeworkTasks ht " +
                             "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                             "WHERE c.TeacherID = @TeacherID " +
                             "ORDER BY ht.DueDate ASC, ht.PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);
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

        // Handles Edit and Delete button clicks from the task table Repeater.
        protected void TaskCommand(object sender, CommandEventArgs e)
        {
            int taskID = Convert.ToInt32(e.CommandArgument);
            int teacherID = Convert.ToInt32(Session["UserID"]);

            if (e.CommandName == "Edit")
            {
                LoadEditForm(taskID, teacherID);
            }
            else if (e.CommandName == "Delete")
            {
                DeleteTask(taskID, teacherID);
            }
        }

        // Populates the edit form with the selected task's current values
        // and makes the edit panel visible.
        private void LoadEditForm(int taskID, int teacherID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Only load the task if it belongs to this teacher (security check)
                string sql = "SELECT ht.TaskID, ht.Title, ht.Subject, ht.Description, " +
                             "ht.DueDate, ht.PriorityLevel " +
                             "FROM HomeworkTasks ht " +
                             "INNER JOIN Classes c ON ht.ClassID = c.ClassID " +
                             "WHERE ht.TaskID = @TaskID AND c.TeacherID = @TeacherID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            hdnEditTaskID.Value = taskID.ToString();
                            txtEditTitle.Text = reader["Title"].ToString();
                            txtEditSubject.Text = reader["Subject"].ToString();
                            txtEditDescription.Text = reader["Description"].ToString();
                            txtEditDueDate.Text = Convert.ToDateTime(reader["DueDate"]).ToString("d/MM/yyyy");
                            ddlEditPriority.SelectedValue = reader["PriorityLevel"].ToString();
                            lblEditTitle.Text = reader["Title"].ToString();
                            pnlEditForm.Visible = true;
                        }
                        else
                        {
                            ShowError("You do not have permission to edit this task.");
                        }
                    }
                }
            }

            LoadTasks();
        }

        // Deletes a task after verifying the teacher owns the class it belongs to.
        // Completion records are deleted first to satisfy the foreign key constraint.
        private void DeleteTask(int taskID, int teacherID)
        {
            // Get the class ID for this task so we can check ownership
            int classID = GetClassIDForTask(taskID);
            if (classID == 0 || !SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                ShowError("You do not have permission to delete this task.");
                LoadTasks();
                return;
            }

            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Delete completion records first, otherwise the foreign key
                // constraint on CompletionRecords.TaskID will block the task deletion
                using (SqlCommand cmd = new SqlCommand(
                    "DELETE FROM CompletionRecords WHERE TaskID = @TaskID", conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.ExecuteNonQuery();
                }
            }

            // Now delete the task itself using PaceTask.Delete()
            bool deleted = PaceTask.Delete(taskID);

            if (deleted)
                ShowSuccess("Task deleted successfully.");
            else
                ShowError("Could not delete the task.");

            pnlEditForm.Visible = false;
            LoadTasks();
        }

        // Saves changes from the edit form back to the database.
        protected void btnSaveEdit_Click(object sender, EventArgs e)
        {
            int taskID = Convert.ToInt32(hdnEditTaskID.Value);
            int teacherID = Convert.ToInt32(Session["UserID"]);

            string title = txtEditTitle.Text.Trim();
            string subject = txtEditSubject.Text.Trim();
            string description = txtEditDescription.Text.Trim();
            string dueDateStr = txtEditDueDate.Text.Trim();
            string priorityStr = ddlEditPriority.SelectedValue;

            bool isValid = true;

            // Existence checks on each field
            if (string.IsNullOrWhiteSpace(title)) { lblEditTitleError.Visible = true; isValid = false; }
            else { lblEditTitleError.Visible = false; }

            if (string.IsNullOrWhiteSpace(subject)) { lblEditSubjectError.Visible = true; isValid = false; }
            else { lblEditSubjectError.Visible = false; }

            if (string.IsNullOrWhiteSpace(description)) { lblEditDescError.Visible = true; isValid = false; }
            else { lblEditDescError.Visible = false; }

            // Type check on due date
            DateTime dueDate;
            if (!DateTime.TryParseExact(dueDateStr, "d/M/yyyy",
                    System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out dueDate))
            {
                lblEditDateError.Visible = true;
                isValid = false;
            }
            else { lblEditDateError.Visible = false; }

            if (!isValid) { pnlEditForm.Visible = true; LoadTasks(); return; }

            int priority = Convert.ToInt32(priorityStr);

            // Security check before updating
            int classID = GetClassIDForTask(taskID);
            if (!SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                ShowError("You do not have permission to edit this task.");
                LoadTasks();
                return;
            }

            // Call PaceTask.Edit() to update the database record
            bool updated = PaceTask.Edit(taskID, title, subject, description, dueDate, priority);

            if (updated)
            {
                pnlEditForm.Visible = false;
                ShowSuccess("Task updated successfully.");
            }
            else
            {
                ShowError("Could not update the task. Please try again.");
                pnlEditForm.Visible = true;
            }

            LoadTasks();
        }

        // Closes the edit form without saving.
        protected void btnCancelEdit_Click(object sender, EventArgs e)
        {
            pnlEditForm.Visible = false;
            pnlSuccess.Visible = false;
            pnlError.Visible = false;
            LoadTasks();
        }

        // Returns the ClassID for a given task. Used for ownership verification.
        private int GetClassIDForTask(int taskID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT ClassID FROM HomeworkTasks WHERE TaskID = @TaskID", conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    object result = cmd.ExecuteScalar();
                    return result != null ? Convert.ToInt32(result) : 0;
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

        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        private void ShowSuccess(string message)
        {
            lblSuccess.Text = message;
            pnlSuccess.Visible = true;
            pnlError.Visible = false;
        }

        private void ShowError(string message)
        {
            lblError.Text = message;
            pnlError.Visible = true;
            pnlSuccess.Visible = false;
        }
    }
}