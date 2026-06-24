using System;
using System.Web;
using System.Web.UI;

namespace PACE
{
    // Code-behind for Login.aspx.
    // Handles server-side validation of login form inputs and authenticates
    // the user against the database via PaceUser.Authenticate().
    // On success, the user is redirected to the page appropriate for their role.
    // On failure, per-field or credential error messages are shown.
    public partial class Login : Page
    {
        // - Page lifecycle -

        // Runs on every request before the page is rendered.
        // If a valid session already exists, the user is redirected away from the
        // login page immediately so they do not see it again unnecessarily.
        protected void Page_Load(object sender, EventArgs e)
        {
            // Check whether a role session variable already exists from a prior login
            string existingRole = Session["Role"] != null ? Session["Role"].ToString() : null;

            if (existingRole == "Teacher")
            {
                // Already logged in as a teacher, send them directly to the teacher dashboard
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            if (existingRole == "Student")
            {
                // Already logged in as a student, send them directly to the student dashboard
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            // No active session: allow the page to render normally so the user can log in
        }

        // - Methods -

        // Fires when the Sign In button is clicked.
        // Validates both fields for existence, then calls PaceUser.Authenticate().
        // If authentication succeeds, redirects by role.
        // If authentication fails, displays the appropriate error UI.
        protected void btnLogin_Click(object sender, EventArgs e)
        {
            // Read the submitted values and trim whitespace
            string username = txtUsername.Text.Trim();
            string password = txtPassword.Text;

            // Track whether any existence check failed
            bool isValid = true;

            // Existence check on username: field must not be empty
            if (string.IsNullOrWhiteSpace(username))
            {
                lblUsernameError.Visible = true;
                txtUsername.CssClass = "field-input error";
                isValid = false;
            }
            else
            {
                // Clear any previous error state on the username field
                lblUsernameError.Visible = false;
                txtUsername.CssClass = "field-input";
            }

            // Existence check on password: field must not be empty
            if (string.IsNullOrEmpty(password))
            {
                lblPasswordError.Visible = true;
                txtPassword.CssClass = "field-input error";
                isValid = false;
            }
            else
            {
                // Clear any previous error state on the password field
                lblPasswordError.Visible = false;
                txtPassword.CssClass = "field-input";
            }

            // If either field failed its existence check, stop here and let the
            // page re-render with the error labels visible
            if (!isValid)
            {
                return;
            }

            // Both fields are present: attempt authentication against the database.
            // PaceUser.Authenticate() handles PBKDF2 hash comparison and,
            // on success, writes UserID, Role, and FullName into the session.
            bool loginSucceeded = PaceUser.Authenticate(username, password);

            if (loginSucceeded)
            {
                // Authentication succeeded: hide any lingering credential error
                pnlLoginError.Visible = false;

                // Read the role that Authenticate() wrote into the session
                string role = Session["Role"] != null ? Session["Role"].ToString() : string.Empty;

                // Redirect to the correct dashboard for this role
                if (role == "Teacher")
                {
                    Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                }
                else
                {
                    Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                }
            }
            else
            {
                // Authentication failed: show the generic credential error banner.
                // The message intentionally does not reveal whether the username
                // or password was incorrect, to prevent user enumeration attacks.
                pnlLoginError.Visible = true;

                // Clear the password field so the user must retype it
                txtPassword.Text = string.Empty;

                // Clear any per-field existence errors that may have been showing,
                // since both fields were filled (the problem is wrong credentials, not empty fields)
                lblUsernameError.Visible = false;
                lblPasswordError.Visible = false;
                txtUsername.CssClass = "field-input";
                txtPassword.CssClass = "field-input";
            }
        }
    }
}