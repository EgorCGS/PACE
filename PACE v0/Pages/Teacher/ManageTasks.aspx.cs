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

        /// <summary>
        /// Enforces the teacher-only session guard, binds the sidebar class list on every
        /// request, and loads the task table on first load.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
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

        /// <summary>
        /// Loads all tasks created by the logged-in teacher across all their classes.
        /// </summary>
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

        /// <summary>
        /// Handles Edit and Delete button clicks from the task table Repeater.
        /// </summary>
        /// <param name="sender">The Repeater raising the command.</param>
        /// <param name="e">Command arguments, carrying the clicked task's ID and command name.</param>
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

        /// <summary>
        /// Populates the edit form with the selected task's current values
        /// and makes the edit panel visible.
        /// </summary>
        /// <param name="taskID">The task to load into the edit form.</param>
        /// <param name="teacherID">The logged-in teacher, used to verify ownership.</param>
        private void LoadEditForm(int taskID, int teacherID)
        {
            // An Edit click always starts a fresh edit session, whether the panel was
            // previously closed or was already open on a different row. Clearing the
            // success/error banners here satisfies "opening edit hides a stale message
            // from a previous action", and clearing the per-field error Labels stops a
            // validation error shown for the last row edited from reappearing against the
            // next row before that row's own Save is even attempted.
            ClearAlerts();
            lblEditTitleError.Visible = false;
            lblEditSubjectError.Visible = false;
            lblEditDescError.Visible = false;
            lblEditDateError.Visible = false;

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
                            // Task not found or not owned by this teacher. Close the panel
                            // and clear the fields that were just populated for whichever
                            // row was open before this click, so a rejected Edit never
                            // leaves stale values sitting behind a closed panel (or, if a
                            // different row was already open, showing through as if they
                            // belonged to this task).
                            hdnEditTaskID.Value = "";
                            txtEditTitle.Text = "";
                            txtEditSubject.Text = "";
                            txtEditDescription.Text = "";
                            txtEditDueDate.Text = "";
                            pnlEditForm.Visible = false;
                            ShowError("You do not have permission to edit this task.");
                        }
                    }
                }
            }

            LoadTasks();
        }

        /// <summary>
        /// Deletes a task after verifying the teacher owns the class it belongs to.
        /// Completion records are deleted first to satisfy the foreign key constraint.
        /// </summary>
        /// <param name="taskID">The task to delete.</param>
        /// <param name="teacherID">The logged-in teacher, used to verify ownership.</param>
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

        /// <summary>
        /// Saves changes from the edit form back to the database.
        /// </summary>
        /// <param name="sender">The Save Changes control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
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

            // Completeness check: title, subject, description and due date are all required.
            // A task missing any of these is incomplete information a student could not act
            // on, so the same completeness standard used on creation applies to edits.
            // Existence checks on each field
            if (string.IsNullOrWhiteSpace(title)) { lblEditTitleError.Visible = true; isValid = false; }
            // Range check on title length, matching HomeworkTasks.Title (nvarchar(150)).
            // The client-side MaxLength on txtEditTitle enforces the same limit, but only
            // limits typing in a browser, it cannot stop an oversized value reaching this
            // handler through a bypassed or hand-crafted request, which would otherwise
            // reach PaceTask.Edit() and throw an unhandled SqlException from SQL Server's
            // own truncation rule instead of this field's own error message.
            else if (title.Length > 150)
            {
                lblEditTitleError.Text = "Title cannot exceed 150 characters.";
                lblEditTitleError.Visible = true;
                isValid = false;
            }
            else { lblEditTitleError.Visible = false; }

            if (string.IsNullOrWhiteSpace(subject)) { lblEditSubjectError.Visible = true; isValid = false; }
            // Range check on subject length, matching HomeworkTasks.Subject
            // (nvarchar(100)) for the same reason as the title check above.
            else if (subject.Length > 100)
            {
                lblEditSubjectError.Text = "Subject cannot exceed 100 characters.";
                lblEditSubjectError.Visible = true;
                isValid = false;
            }
            else { lblEditSubjectError.Visible = false; }

            if (string.IsNullOrWhiteSpace(description)) { lblEditDescError.Visible = true; isValid = false; }
            // Range check on description length, matching HomeworkTasks.Description
            // (nvarchar(1000)) for the same reason as the title and subject checks
            // above. This field's textarea previously had no client-side MaxLength at
            // all, so this was the only barrier standing between a long edited
            // description and an unhandled SqlException.
            else if (description.Length > 1000)
            {
                lblEditDescError.Text = "Description cannot exceed 1000 characters.";
                lblEditDescError.Visible = true;
                isValid = false;
            }
            else { lblEditDescError.Visible = false; }

            // Type check on due date
            DateTime dueDate;
            if (!DateTime.TryParseExact(dueDateStr, "d/M/yyyy",
                    System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out dueDate))
            {
                lblEditDateError.Text = "Must be a valid date in DD/MM/YYYY format.";
                lblEditDateError.Visible = true;
                isValid = false;
            }
            else
            {
                // Reasonableness check: a due date before today cannot give students any
                // time to complete the task, so it is not a usable value even though it
                // parsed as a valid date. This also catches accidental data-entry errors,
                // such as typing the wrong year or day, before they reach the database.
                // This only fires when the teacher is actually changing the due date to a
                // past value. An existing task that has simply become overdue since it was
                // created must still be editable (for example, fixing a typo in the title)
                // without being forced to push the due date into the future first.
                DateTime originalDueDate = GetOriginalDueDate(taskID);
                if (dueDate.Date != originalDueDate.Date && dueDate.Date < DateTime.Today)
                {
                    lblEditDateError.Text = "Due date cannot be in the past.";
                    lblEditDateError.Visible = true;
                    isValid = false;
                }
                else { lblEditDateError.Visible = false; }
            }

            // A validation failure keeps the panel open on the same row (Visible was already
            // true when this postback started, so this just re-affirms it) and shows its own
            // per-field error Labels, not the pnlSuccess/pnlError banners, which is why
            // neither ShowSuccess nor ShowError is called on this path.
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

        /// <summary>
        /// Closes the edit form without saving. No success or error message is shown,
        /// cancelling is not itself an outcome worth reporting.
        /// </summary>
        /// <param name="sender">The Cancel control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnCancelEdit_Click(object sender, EventArgs e)
        {
            pnlEditForm.Visible = false;
            ClearAlerts();
            LoadTasks();
        }

        /// <summary>
        /// Returns the ClassID for a given task. Used for ownership verification.
        /// </summary>
        /// <param name="taskID">The task to look up.</param>
        /// <returns>The task's ClassID, or 0 if the task does not exist.</returns>
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

        /// <summary>
        /// Returns the currently stored due date for a task. Used by the reasonableness
        /// check in btnSaveEdit_Click to tell an unchanged (now overdue) due date apart
        /// from a newly entered past date.
        /// </summary>
        /// <param name="taskID">The task to look up.</param>
        /// <returns>The task's currently stored due date, or DateTime.MinValue if the task does not exist.</returns>
        private DateTime GetOriginalDueDate(int taskID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand(
                    "SELECT DueDate FROM HomeworkTasks WHERE TaskID = @TaskID", conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    object result = cmd.ExecuteScalar();
                    return result != null ? Convert.ToDateTime(result) : DateTime.MinValue;
                }
            }
        }

        /// <summary>
        /// Logs the teacher out and returns to the login page.
        /// </summary>
        /// <param name="sender">The logout control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        /// <summary>
        /// Builds a one or two letter initials string from the logged-in user's full name,
        /// for display in the sidebar avatar.
        /// </summary>
        /// <returns>The user's initials in upper case, or "?" if no name is available.</returns>
        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        /// <summary>
        /// Returns an HTML badge for a task's priority level.
        /// </summary>
        /// <param name="priorityObj">The PriorityLevel value from the data source (1, 2, or 3).</param>
        /// <returns>An HTML span with the appropriate badge class and label.</returns>
        protected string GetPriorityBadge(object priorityObj)
        {
            int p = Convert.ToInt32(priorityObj);
            if (p == 3) return "<span class=\"badge badge-high\">High</span>";
            if (p == 2) return "<span class=\"badge badge-med\">Med</span>";
            return "<span class=\"badge badge-low\">Low</span>";
        }

        // pnlSuccess and pnlError are both kept in the DOM at all times (see markup), so
        // "showing" one is purely a CSS class swap, never a Visible change, and the two are
        // always set together so exactly one is ever unhidden at a time.
        /// <summary>
        /// Shows the success banner with the given message and hides the error banner.
        /// </summary>
        /// <param name="message">The success message to display.</param>
        private void ShowSuccess(string message)
        {
            lblSuccess.Text = message;
            pnlSuccess.CssClass = "alert-success-wrap";
            pnlError.CssClass = "alert-error-wrap alert-hidden";
        }

        /// <summary>
        /// Shows the error banner with the given message and hides the success banner.
        /// </summary>
        /// <param name="message">The error message to display.</param>
        private void ShowError(string message)
        {
            lblError.Text = message;
            pnlError.CssClass = "alert-error-wrap";
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";
        }

        /// <summary>
        /// Hides both banners without showing either, used when an action (Edit, Cancel)
        /// should clear away any leftover message from a previous action rather than
        /// replace it with a new one.
        /// </summary>
        private void ClearAlerts()
        {
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";
            pnlError.CssClass = "alert-error-wrap alert-hidden";
        }
    }
}