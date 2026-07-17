using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace PACE
{
    // Code-behind for the teacher per-class overview page.
    // Shows completion statistics by task and by student for the selected class, plus two graphs
    // (student distribution and completion trend) built on the same StatisticsReport data.
    // Accessed by clicking a class name in the teacher sidebar.
    public partial class TeacherClassPage : Page
    {
        // Stores the current class ID so the sidebar can highlight the active class
        private int _currentClassID = 0;

        // Stores the largest single day completion count from the trend graph's data, set by
        // LoadCompletionTrend before the trend repeater binds. int rather than recomputing it inside
        // GetTrendBarHeight on every repeater item, the max is a property of the whole result set, not of
        // any single row, so it needs to be worked out once up front and then just read back per row.
        private int _trendMaxCount = 0;

        // - Page lifecycle -

        /// <summary>
        /// Enforces the teacher-only session guard, reads and validates the ClassID query
        /// string, verifies class ownership, and on first load binds the sidebar, hero
        /// title, breadcrumb and class statistics.
        /// </summary>
        /// <param name="sender">The page raising the event.</param>
        /// <param name="e">Event arguments (unused).</param>
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["Role"] == null) { Response.Redirect("~/Login.aspx"); return; }
            if (Session["Role"].ToString() != "Teacher") { Response.Redirect("~/Pages/Student/StudentDashboard.aspx"); return; }

            int teacherID = Convert.ToInt32(Session["UserID"]);

            // Read ClassID from the URL query string
            int classID = 0;
            if (!int.TryParse(Request.QueryString["ClassID"], out classID) || classID <= 0)
            {
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            // Verify this teacher owns the class before showing anything
            if (!SchoolClass.IsOwnedByTeacher(classID, teacherID))
            {
                Response.Redirect("~/Pages/Teacher/TeacherDashboard.aspx");
                return;
            }

            _currentClassID = classID;

            // Load sidebar classes and bind, highlighting the active class
            List<SchoolClass> classes = SchoolClass.GetClassesByTeacher(teacherID);
            rptSidebarClasses.DataSource = classes;
            rptSidebarClasses.DataBind();

            if (!IsPostBack)
            {
                // Find the class name for the hero and breadcrumb
                string className = "";
                foreach (SchoolClass sc in classes)
                {
                    if (sc.ClassID == classID) { className = sc.ClassName; break; }
                }

                lblHeroTitle.Text = className;
                lblBreadcrumb.Text = className;

                LoadStats(classID);
            }
        }

        // - Methods -

        /// <summary>
        /// Loads task level and student level statistics for the selected class, and feeds the two
        /// graphs below from the same data. Calls StatisticsReport.Generate(classID) once as the single
        /// entry point rather than running its own duplicate inline SQL for student stats, so the tables
        /// and both graphs are always built from one consistent snapshot instead of querying the database
        /// twice for numbers that should agree with each other.
        /// </summary>
        /// <param name="classID">The class to load statistics for.</param>
        private void LoadStats(int classID)
        {
            StatisticsReport report = StatisticsReport.Generate(classID);

            DataTable taskStats = report.TaskStats;
            DataTable studentStats = report.StudentStats;
            int enrolledCount = report.TotalStudents;
            int totalTasks = taskStats.Rows.Count;

            // Compute overall completion percentage across all tasks and students
            double overallPct = 0;
            if (totalTasks > 0 && enrolledCount > 0)
            {
                double totalCompletions = 0;
                foreach (DataRow row in taskStats.Rows)
                    totalCompletions += Convert.ToInt32(row["CompletionCount"]);
                overallPct = Math.Round(totalCompletions / (totalTasks * enrolledCount) * 100, 1);
            }

            lblTotalStudents.Text = enrolledCount.ToString();
            lblTotalTasks.Text = totalTasks.ToString();
            lblOverallPct.Text = overallPct + "%";

            rptTaskStats.DataSource = taskStats;
            rptTaskStats.DataBind();
            pnlNoTasks.Visible = taskStats.Rows.Count == 0;

            rptStudentStats.DataSource = studentStats;
            rptStudentStats.DataBind();
            pnlNoStudents.Visible = studentStats.Rows.Count == 0;

            LoadStudentDistribution(studentStats, totalTasks);
            LoadCompletionTrend(report.CompletionTrend);
        }

        /// <summary>
        /// Buckets each enrolled student into On Track (75% or higher), At Risk (40% up to 75%) or
        /// Behind (under 40%) based on their completion percentage for this class, then feeds the counts
        /// into the Student Distribution stacked bar graph. Plain int counters and three fixed asp:Panel
        /// segments are used instead of a Repeater over a small List&lt;T&gt;, the bucket set is fixed at exactly
        /// three known categories (never data driven, never a variable count), so looping through a
        /// collection to render three always-present segments would add indirection without buying any
        /// flexibility this graph actually needs.
        /// </summary>
        /// <param name="studentStats">Per-student completion counts for the selected class.</param>
        /// <param name="totalTasksInClass">The total number of tasks assigned to the class.</param>
        private void LoadStudentDistribution(DataTable studentStats, int totalTasksInClass)
        {
            int onTrack = 0;
            int atRisk = 0;
            int behind = 0;

            // A class with no tasks yet has no meaningful completion percentage to bucket students by,
            // so the distribution graph is skipped entirely rather than dividing by zero or showing a
            // misleading "0% for everyone" chart.
            if (totalTasksInClass > 0)
            {
                foreach (DataRow row in studentStats.Rows)
                {
                    int completed = Convert.ToInt32(row["TasksCompleted"]);
                    int total = Convert.ToInt32(row["TotalTasks"]);
                    double pct = total > 0 ? (double)completed / total * 100 : 0;

                    if (pct >= 75) onTrack++;
                    else if (pct >= 40) atRisk++;
                    else behind++;
                }
            }

            int chartTotal = onTrack + atRisk + behind;

            lblOnTrackCount.Text = onTrack.ToString();
            lblAtRiskCount.Text = atRisk.ToString();
            lblBehindCount.Text = behind.ToString();

            pnlOnTrackSeg.Width = Unit.Percentage(chartTotal > 0 ? (double)onTrack / chartTotal * 100 : 0);
            pnlAtRiskSeg.Width = Unit.Percentage(chartTotal > 0 ? (double)atRisk / chartTotal * 100 : 0);
            pnlBehindSeg.Width = Unit.Percentage(chartTotal > 0 ? (double)behind / chartTotal * 100 : 0);

            // Empty when there are no tasks to measure progress against, or no students to measure
            bool isEmpty = totalTasksInClass == 0 || chartTotal == 0;
            pnlDistributionEmpty.Visible = isEmpty;
            pnlDistributionChart.Visible = !isEmpty;
        }

        /// <summary>
        /// Binds the Completion Trend graph from StatisticsReport.GenerateCompletionTrend's output.
        /// Works out the largest single day count first (_trendMaxCount) so each bar's height can be
        /// expressed as a percentage of the busiest day, the same relative-height approach the pct-track
        /// bars elsewhere on this page use for percentages, just re-purposed here for raw daily counts
        /// instead of a 0-100 ratio.
        /// </summary>
        /// <param name="trend">Per-day completion counts for the selected class over the trend window.</param>
        private void LoadCompletionTrend(DataTable trend)
        {
            _trendMaxCount = 0;
            foreach (DataRow row in trend.Rows)
            {
                int count = Convert.ToInt32(row["CompletionCount"]);
                if (count > _trendMaxCount) _trendMaxCount = count;
            }

            rptCompletionTrend.DataSource = trend;
            rptCompletionTrend.DataBind();

            pnlTrendEmpty.Visible = trend.Rows.Count == 0;
            pnlTrendChart.Visible = trend.Rows.Count > 0;
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
        /// Returns the sidebar nav CSS class for a class link, highlighting the class
        /// currently being viewed.
        /// </summary>
        /// <param name="classIDObj">The ClassID value from the data source.</param>
        /// <returns>"nav-item active" for the current class, "nav-item" for all others.</returns>
        protected string GetNavClass(object classIDObj)
        {
            return Convert.ToInt32(classIDObj) == _currentClassID
                ? "nav-item active"
                : "nav-item";
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
        /// Returns initials for the student avatar in the student stats table.
        /// </summary>
        /// <param name="nameObj">The FullName value from the data source.</param>
        /// <returns>The student's initials in upper case, or "?" if no name is available.</returns>
        protected string GetStudentInitials(object nameObj)
        {
            string name = nameObj != null ? nameObj.ToString() : "?";
            string[] parts = name.Trim().Split(' ');
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        /// <summary>
        /// Colour codes the student row (avatar and name) so Mrs Bright can scan for
        /// at-risk students at a glance: red for zero completions, orange for partial,
        /// green for fully complete.
        /// </summary>
        /// <param name="tasksCompletedObj">The TasksCompleted value from the data source.</param>
        /// <param name="totalTasksObj">The TotalTasks value from the data source.</param>
        /// <returns>The CSS class for the row's colour state.</returns>
        protected string GetStudentRowClass(object tasksCompletedObj, object totalTasksObj)
        {
            int tasksCompleted = Convert.ToInt32(tasksCompletedObj);
            int totalTasks = Convert.ToInt32(totalTasksObj);

            if (totalTasks > 0 && tasksCompleted == totalTasks) return "student-complete";
            if (tasksCompleted > 0 && tasksCompleted < totalTasks) return "student-partial";
            return "student-behind";
        }

        /// <summary>
        /// Returns the progress bar colour class for a completion percentage.
        /// </summary>
        /// <param name="pctObj">The completion percentage.</param>
        /// <returns>"zero", "green", "orange", or "" (red) depending on the percentage band.</returns>
        protected string GetPctClass(object pctObj)
        {
            double pct = Convert.ToDouble(pctObj);
            if (pct == 0) return "zero";
            if (pct >= 70) return "green";
            if (pct >= 40) return "orange";
            return "";
        }

        /// <summary>
        /// Computes a student's completion percentage for display, rounded to the nearest whole number.
        /// </summary>
        /// <param name="completedObj">The number of tasks completed.</param>
        /// <param name="totalObj">The total number of tasks assigned.</param>
        /// <returns>The rounded completion percentage as a string, or "0" if there are no tasks.</returns>
        protected string GetStudentPct(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return "0";
            return Math.Round((double)completed / total * 100, 0).ToString();
        }

        /// <summary>
        /// Computes a student's completion percentage at one decimal place of precision,
        /// used for colour banding rather than display.
        /// </summary>
        /// <param name="completedObj">The number of tasks completed.</param>
        /// <param name="totalObj">The total number of tasks assigned.</param>
        /// <returns>The completion percentage, or 0 if there are no tasks.</returns>
        protected double GetStudentPctRaw(object completedObj, object totalObj)
        {
            int completed = Convert.ToInt32(completedObj);
            int total = Convert.ToInt32(totalObj);
            if (total == 0) return 0;
            return Math.Round((double)completed / total * 100, 1);
        }

        /// <summary>
        /// Returns a bar height percentage for the Completion Trend graph, relative to the busiest day
        /// in the current window (_trendMaxCount). A floor of 8 is applied so a day with only one or two
        /// completions still renders a visible sliver of a bar instead of disappearing next to a much
        /// busier day, every row here has at least one completion by construction (the underlying query
        /// only groups dates that had at least one), so there is no zero-count case to worry about.
        /// </summary>
        /// <param name="countObj">The CompletionCount value for the day.</param>
        /// <returns>The bar height as a percentage string, floored at 8.</returns>
        protected string GetTrendBarHeight(object countObj)
        {
            int count = Convert.ToInt32(countObj);
            if (_trendMaxCount <= 0) return "8";
            double pct = (double)count / _trendMaxCount * 100;
            return Math.Max(pct, 8).ToString("0");
        }

        /// <summary>
        /// Short day/month label shown under each bar in the Completion Trend graph.
        /// </summary>
        /// <param name="dateObj">The CompletionDate value for the bar.</param>
        /// <returns>The date formatted as "dd/MM".</returns>
        protected string GetTrendDateLabel(object dateObj)
        {
            DateTime date = Convert.ToDateTime(dateObj);
            return date.ToString("dd/MM");
        }

        /// <summary>
        /// Full date and count shown as a native title tooltip on hover, since the bar itself only has
        /// room for a short day/month label.
        /// </summary>
        /// <param name="dateObj">The CompletionDate value for the bar.</param>
        /// <param name="countObj">The CompletionCount value for the bar.</param>
        /// <returns>A formatted tooltip string, e.g. "12 Mar 2026: 3 completions".</returns>
        protected string GetTrendTooltip(object dateObj, object countObj)
        {
            DateTime date = Convert.ToDateTime(dateObj);
            int count = Convert.ToInt32(countObj);
            return date.ToString("dd MMM yyyy") + ": " + count + (count == 1 ? " completion" : " completions");
        }
    }
}
