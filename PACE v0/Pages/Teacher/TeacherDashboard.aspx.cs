using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    public partial class TeacherDashboard : Page
    {
        // - Page lifecycle -

        /// <summary>
        /// Enforces the teacher-only session guard, binds the sidebar class list on every
        /// request, and loads the dashboard summary and per-class stats on first load.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                lblHeroName.Text = Session["FullName"].ToString();
                LoadDashboard(teacherID);
            }
        }

        // - Methods -

        /// <summary>
        /// Loads per-class stats and computes summary totals.
        /// Hides the dashboard panel and shows a first-run state if no classes exist.
        /// </summary>
        /// <param name="teacherID">The logged-in teacher whose classes should be summarised.</param>
        private void LoadDashboard(int teacherID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;
            DataTable dt = new DataTable();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql =
                    "SELECT c.ClassID, c.ClassName, " +
                    "(SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = c.ClassID) AS StudentCount, " +
                    "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = c.ClassID) AS TaskCount, " +
                    "(SELECT COUNT(*) FROM CompletionRecords cr " +
                    " INNER JOIN HomeworkTasks ht ON cr.TaskID = ht.TaskID " +
                    " WHERE ht.ClassID = c.ClassID AND cr.MarkedComplete = 1) AS CompletionCount, " +
                    "(SELECT COUNT(*) FROM HomeworkTasks ht2 " +
                    " WHERE ht2.ClassID = c.ClassID AND ht2.DueDate < CAST(GETDATE() AS DATE)) AS OverdueTasks " +
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

            // If no classes exist, show first-run state instead of dashboard
            if (dt.Rows.Count == 0)
            {
                pnlNoClasses.Visible = true;
                pnlDashboard.Visible = false;
                lblTotalClasses.Text = "0";
                lblTotalStudents.Text = "0";
                lblTotalTasks.Text = "0";
                lblOverallPct.Text = "0%";
                return;
            }

            pnlNoClasses.Visible = false;
            pnlDashboard.Visible = true;

            // Add computed display columns
            dt.Columns.Add("Percentage", typeof(double));
            dt.Columns.Add("PctDisplay", typeof(string));
            dt.Columns.Add("PctClass", typeof(string));
            dt.Columns.Add("PctColor", typeof(string));
            dt.Columns.Add("PctWidth", typeof(string));
            dt.Columns.Add("AccentClass", typeof(string));

            int totalStudents = 0;
            int totalTasks = 0;
            int totalCompletions = 0;
            int totalMaxPossible = 0;

            foreach (DataRow row in dt.Rows)
            {
                int students = Convert.ToInt32(row["StudentCount"]);
                int tasks = Convert.ToInt32(row["TaskCount"]);
                int completions = Convert.ToInt32(row["CompletionCount"]);
                int maxPossible = students * tasks;

                double pct = maxPossible > 0
                    ? Math.Round((double)completions / maxPossible * 100, 1) : 0;

                row["Percentage"] = pct;
                row["PctDisplay"] = pct.ToString("0") + "%";

                if (tasks == 0) { row["PctClass"] = "zero"; row["PctColor"] = "#7a9fbe"; row["AccentClass"] = ""; }
                else if (pct >= 70) { row["PctClass"] = "green"; row["PctColor"] = "#3a9e6e"; row["AccentClass"] = "green"; }
                else if (pct >= 40) { row["PctClass"] = "orange"; row["PctColor"] = "#d4882a"; row["AccentClass"] = "orange"; }
                else { row["PctClass"] = ""; row["PctColor"] = "#d95c5c"; row["AccentClass"] = "red"; }

                row["PctWidth"] = Math.Min(pct, 100).ToString("0");

                totalStudents += students;
                totalTasks += tasks;
                totalCompletions += completions;
                totalMaxPossible += maxPossible;
            }

            lblTotalClasses.Text = dt.Rows.Count.ToString();
            lblTotalStudents.Text = totalStudents.ToString();
            lblTotalTasks.Text = totalTasks.ToString();

            double overallPct = totalMaxPossible > 0
                ? Math.Round((double)totalCompletions / totalMaxPossible * 100, 1) : 0;
            lblOverallPct.Text = overallPct + "%";

            rptClasses.DataSource = dt;
            rptClasses.DataBind();
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