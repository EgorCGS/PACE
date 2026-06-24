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
            }
        }

        // - Methods -

        // Loads the teacher's own classes into the class dropdown.
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

        // Fires when the Create Task button is clicked.
        // Validates inputs then calls PaceTask.ValidateInputs() and PaceTask.Create().
        protected void btnCreateTask_Click(object sender, EventArgs e)
        {
            // Read form values
            string classIDStr = ddlClass.SelectedValue;
            string title = txtTitle.Text.Trim();
            string subject = txtSubject.Text.Trim();
            string description = txtDescription.Text.Trim();
            string dueDateStr = txtDueDate.Text.Trim();
            string priorityStr = hdnPriority.Value;

            bool isValid = true;

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

            // Type check on due date using PaceTask.ValidateInputs() for the date/priority portion
            DateTime dueDate;
            if (!DateTime.TryParseExact(dueDateStr, "d/M/yyyy",
                    System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out dueDate))
            {
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
            // Note: ensure HomeworkTask.cs has been updated to use HomeworkTasks not PaceTasks
            int newTaskID = PaceTask.Create(classID, title, subject, description, dueDate, priority);

            if (newTaskID > 0)
            {
                // Task created successfully: show success message and clear the form
                lblSuccess.Text = "Task \"" + title + "\" was created successfully (Task ID: " + newTaskID + ").";
                pnlSuccess.Visible = true;

                txtTitle.Text = string.Empty;
                txtSubject.Text = string.Empty;
                txtDescription.Text = string.Empty;
                txtDueDate.Text = string.Empty;
                hdnPriority.Value = "2";

                // Reload the class dropdown to keep it populated after postback
                LoadClasses();
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
    }
}