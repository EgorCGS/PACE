using System;
using System.Collections.Generic;
using System.Web.UI;

namespace PACE
{
    // Code-behind for the teacher main dashboard.
    // Loads the teacher's classes for the sidebar and sets the hero greeting.
    public partial class TeacherDashboard : Page
    {
        // - Page lifecycle -

        protected void Page_Load(object sender, EventArgs e)
        {
            // Redirect to login if no session exists
            if (Session["Role"] == null)
            {
                Response.Redirect("~/Login.aspx");
                return;
            }

            // Redirect students away from teacher pages
            if (Session["Role"].ToString() != "Teacher")
            {
                Response.Redirect("~/Pages/Student/StudentDashboard.aspx");
                return;
            }

            if (!IsPostBack)
            {
                lblHeroName.Text = Session["FullName"].ToString();

                // Load teacher's classes for the sidebar using SchoolClass.GetClassesByTeacher()
                int teacherID = Convert.ToInt32(Session["UserID"]);
                List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);
                rptSidebarClasses.DataSource = classes;
                rptSidebarClasses.DataBind();
            }
        }

        // - Methods -

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PaceUser.Logout();
            Response.Redirect("~/Login.aspx");
        }

        // Returns teacher's initials for the sidebar avatar.
        protected string GetInitials()
        {
            string name = Session["FullName"] != null ? Session["FullName"].ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }
    }
}