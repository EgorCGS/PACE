using System;
using System.Collections.Generic;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the teacher task creation page.
    // Validates all form inputs, checks class ownership, and calls PaceTask.Create().
    public partial class CreateTask : Page
    {
        // - Page lifecycle -

        /// <summary>
        /// Enforces the teacher-only session guard, binds the sidebar class list on every
        /// request, and on first load populates the class dropdown and applies any
        /// pre-selected ClassID passed in the query string.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null)
            {
                Response.Redirect("~/Login.aspx");
                return;
            }

            if (Session["Role"].ToString() != "Teacher")
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            List<SchoolClass> sidebarClasses = SchoolClass.GetClassesByTeacher(Convert.ToInt32(Session["UserID"]));
            rptSidebarClasses.DataSource = sidebarClasses;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                // Populate class dropdown using SchoolClass.GetClassesByTeacher()
                LoadClasses();

                // Pre-select the class if arriving from a class-specific page
                // (for example TeacherClassPage's "Create Task" button or
                // TeacherDashboard's "Add Task" card link, both of which pass
                // ?ClassID=). Only applied on first load, never on postback,
                // so a teacher's own dropdown choice is never overwritten by
                // a stale query string value on a later postback.
                int queryClassID;
                if (int.TryParse(Request.QueryString["ClassID"], out queryClassID) && queryClassID > 0
                    && SchoolClass.IsOwnedByTeacher(queryClassID, Convert.ToInt32(Session["UserID"])))
                {
                    ddlClass.SelectedValue = queryClassID.ToString();
                }
            }
        }

        // - Methods -

        /// <summary>
        /// Loads the teacher's own classes into the class dropdown.
        /// </summary>
        private void LoadClasses()
        {
            int teacherID = Convert.ToInt32(Session["UserID"]);

            // Uses SchoolClass.GetClassesByTeacher() from App_Code
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);

            ddlClass.DataSource = classes;
            ddlClass.DataTextField = "ClassName";
            ddlClass.DataValueField = "ClassID";
            ddlClass.DataBind();

            // Add a blank prompt at the top if there are multiple classes
            if (classes.Count > 1)
                ddlClass.Items.Insert(0, new System.Web.UI.WebControls.ListItem("-- Select a class --", "0"));
        }

        /// <summary>
        /// Fires when the Create Task button is clicked. Validates every field, verifies
        /// class ownership, then calls PaceTask.Create() to insert the new task.
        /// </summary>
        /// <param name="sender">The Create Task control raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void btnCreateTask_Click(object sender, EventArgs e)
        {
            // Read form values
            string classIDStr = ddlClass.SelectedValue;
            string title = txtTitle.Text.Trim();
            string subject = txtSubject.Text.Trim();
            string description = txtDescription.Text.Trim();
            string dueDateStr = txtDueDate.Text.Trim();
            string priorityStr = hdnPriority.Value;

            // Clear any success message left over from a previous submission before this
            // one is validated, so a failed resubmission never shows a stale "created"
            // banner from the last successful create. The panel itself stays in the DOM
            // either way (see pnlSuccess markup), only its paint toggles here.
            pnlSuccess.CssClass = "alert-success-wrap alert-hidden";

            bool isValid = true;

            // Completeness check: class, title, subject, description, due date and priority
            // are all required. A task missing any one of these is incomplete information
            // a student could not act on (for example, a task with no due date cannot be
            // shown as upcoming or overdue, and a task with no class cannot be assigned).
            // Existence check on class selection
            if (classIDStr == "0" || string.IsNullOrWhiteSpace(classIDStr))
            {
                lblClassError.Visible = true;
                isValid = false;
            }
            else { lblClassError.Visible = false; }

            // Existence check on title
            if (string.IsNullOrWhiteSpace(title))
            {
                lblTitleError.Visible = true;
                txtTitle.CssClass = "form-input error";
                isValid = false;
            }
            else { lblTitleError.Visible = false; txtTitle.CssClass = "form-input"; }

            // Existence check on subject
            if (string.IsNullOrWhiteSpace(subject))
            {
                lblSubjectError.Visible = true;
                txtSubject.CssClass = "form-input error";
                isValid = false;
            }
            else { lblSubjectError.Visible = false; txtSubject.CssClass = "form-input"; }

            // Existence check on description
            if (string.IsNullOrWhiteSpace(description))
            {
                lblDescError.Visible = true;
                isValid = false;
            }
            else { lblDescError.Visible = false; }

            // Type check on due date, validation is implemented inline here rather than via
            // PaceTask.ValidateInputs(), since this page's reasonableness check (due date
            // must not be in the past) always fires, unlike ManageTasks where it only fires
            // when the due date value has actually changed
            DateTime dueDate;
            if (!DateTime.TryParseExact(dueDateStr, "d/M/yyyy",
                    System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out dueDate))
            {
                lblDateError.Text = "Must be a valid date in DD/MM/YYYY format.";
                lblDateError.Visible = true;
                txtDueDate.CssClass = "form-input error";
                isValid = false;
            }
            else if (dueDate.Date < DateTime.Today)
            {
                // Reasonableness check: a due date before today cannot give students any
                // time to complete the task, so it is not a usable value even though it
                // parsed as a valid date. This also catches accidental data-entry errors,
                // such as typing the wrong year or day, before they reach the database.
                lblDateError.Text = "Due date cannot be in the past.";
                lblDateError.Visible = true;
                txtDueDate.CssClass = "form-input error";
                isValid = false;
            }
            else { lblDateError.Visible = false; txtDueDate.CssClass = "form-input"; }

            // Range check on priority (must be 1, 2, or 3)
            int priority;
            if (!int.TryParse(priorityStr, out priority) || priority < 1 || priority > 3)
            {
                // Priority toggle buttons prevent this in normal use,
                // but the server-side check runs regardless (FR10)
                isValid = false;
            }

            if (!isValid) return;

            int classID = Convert.ToInt32(classIDStr);
            int teacherID = Convert.ToInt32(Session["UserID"]);

            // Security check: confirm this class belongs to the logged-in teacher
            if (!SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                lblClassError.Text = "You do not have access to this class.";
                lblClassError.Visible = true;
                return;
            }

            // All checks passed: create the task using PaceTask.Create()
            int newTaskID = PaceTask.Create(classID, title, subject, description, dueDate, priority);

            if (newTaskID > 0)
            {
                // Task created successfully: show success message and clear the form
                lblSuccess.Text = "Task \"" + title + "\" was created successfully (Task ID: " + newTaskID + ").";
                pnlSuccess.CssClass = "alert-success-wrap";

                txtTitle.Text = string.Empty;
                txtSubject.Text = string.Empty;
                txtDescription.Text = string.Empty;
                txtDueDate.Text = string.Empty;
                hdnPriority.Value = "2";

                // Reload the class dropdown to keep it populated after postback
                LoadClasses();
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
    }
}