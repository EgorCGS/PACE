using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace PACE
{
    // Represents the statistics report for a specific class.
    // Used by the teacher's statistics dashboard to show completion rates
    // across all tasks and all enrolled students.
    public class StatisticsReport
    {
        // - Attributes -

        // The ID of the class this report is generated for.
        // int for the same identity/foreign key matching reason used throughout the other App_Code
        // classes, ClassID is compared directly against Classes.ClassID (also SQL int) in every query
        // this class runs, so no conversion is needed between the C# object and the SQL parameter.
        public int ClassID { get; set; }

        // The total number of students enrolled in the class.
        // int, a plain count with no fractional meaning, this value is also what CalculatePercentage and
        // GenerateTaskStats divide by, so it needs to be a whole number obtained once (in Generate) and
        // reused, rather than re-queried separately by each statistic that needs it.
        public int TotalStudents { get; set; }

        // A table of task level statistics, one row per task.
        // Columns: TaskID, Title, CompletionCount, TotalStudents, Percentage
        // DataTable is used here, a deliberate departure from the List<T> pattern used by every other
        // class in the app (PaceTask, SchoolClass, CompletionRecord), because this result set does not
        // correspond to any single real world entity, it is computed and aggregated across two tables
        // (HomeworkTasks and CompletionRecords) with columns like CompletionCount and Percentage that only
        // exist as the output of a GROUP BY query, not as fields on any one row in the database. Inventing
        // a typed class (e.g. "TaskStatRow") purely to hold this query's output would add a class whose
        // only purpose is to mirror a SELECT list, whereas DataTable already models a multi-source,
        // computed, tabular result and binds directly to the Repeater on the statistics page with no
        // extra mapping step.
        public DataTable TaskStats { get; set; }

        // A table of student level statistics, one row per student.
        // Columns: StudentID, FullName, TasksCompleted, TotalTasks
        // DataTable for the same reason as TaskStats above, this result also spans multiple tables
        // (Users, ClassEnrolments, CompletionRecords, HomeworkTasks) and carries a computed aggregate
        // column (TasksCompleted) that has no home on any single entity class, a genuine multi-source
        // computed result rather than a real object in the data model.
        public DataTable StudentStats { get; set; }

        // A table of completions per calendar day for the class, over a recent window.
        // Columns: CompletionDate, CompletionCount
        // DataTable for the same reason as TaskStats and StudentStats above, a computed aggregate
        // (a COUNT grouped by date) with no corresponding entity class.
        public DataTable CompletionTrend { get; set; }

        // - Methods -

        /// <summary>
        /// Generates the task level statistics table for a specific class, showing how many students
        /// have completed each task and the completion percentage.
        /// </summary>
        /// <param name="classID">The class to generate task statistics for.</param>
        /// <returns>A DataTable with columns TaskID, Title, CompletionCount, TotalStudents, Percentage.</returns>
        public DataTable GenerateTaskStats(int classID)
        {
            DataTable taskStats = new DataTable();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // For each task in the class, count how many students have MarkedComplete = 1.
                // LEFT JOIN ensures tasks with zero completions still appear in the results.
                // ht.DueDate is included in the GROUP BY alongside ht.TaskID and ht.Title even though it is
                // only used for ordering, not selected as its own column, because SQL Server requires every
                // non-aggregate column referenced anywhere in the SELECT list to appear in the GROUP BY
                // clause, and TaskID/Title alone are not enough once DueDate is pulled into the query
                // through the ORDER BY. Leaving DueDate out of GROUP BY previously caused a SqlException at
                // runtime, this comment exists so a future edit that adds another selected or ordered
                // column remembers to update GROUP BY at the same time, rather than reintroducing that
                // same exception.
                string sql = "SELECT ht.TaskID, ht.Title, " +
                             "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS CompletionCount, " +
                             "@TotalStudents AS TotalStudents " +
                             "FROM HomeworkTasks ht " +
                             "LEFT JOIN CompletionRecords cr ON ht.TaskID = cr.TaskID " +
                             "WHERE ht.ClassID = @ClassID " +
                             "GROUP BY ht.TaskID, ht.Title, ht.DueDate " +
                             "ORDER BY ht.DueDate ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@TotalStudents", TotalStudents);

                    using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(taskStats);
                    }
                }
            }

            // Add a calculated Percentage column to the table after filling it.
            // This is calculated in C# rather than SQL for clarity and flexibility.
            taskStats.Columns.Add("Percentage", typeof(double));
            foreach (DataRow row in taskStats.Rows)
            {
                int completionCount = Convert.ToInt32(row["CompletionCount"]);
                int total = Convert.ToInt32(row["TotalStudents"]);

                // Avoid dividing by zero if the class has no students enrolled
                row["Percentage"] = total > 0
                    ? Math.Round((double)completionCount / total * 100, 1)
                    : 0.0;
            }

            return taskStats;
        }

        /// <summary>
        /// Generates the student level statistics table for a specific class, showing how many tasks
        /// each student has completed out of the total assigned.
        /// </summary>
        /// <param name="classID">The class to generate student statistics for.</param>
        /// <returns>A DataTable with columns StudentID, FullName, TasksCompleted, TotalTasks.</returns>
        // Computes, per enrolled student, a TasksCompleted count (from CompletionRecords where
        // MarkedComplete = 1) alongside a TotalTasks count (all tasks belonging to the class), so the
        // statistics page can show each student's individual completion ratio next to the class wide
        // per-task figures produced by GenerateTaskStats. HomeworkTasks is joined first, scoped to this
        // class only (ht.ClassID = @ClassID in the ON clause, not WHERE), and CompletionRecords is then
        // joined to that specific student and task pair (cr.StudentID = u.UserID AND cr.TaskID = ht.TaskID).
        // Both joins are LEFT JOINs, which matters for two separate reasons, first, a student with zero
        // completions in this class still gets one row per task with cr all NULL rather than being dropped,
        // second, and just as important, joining CompletionRecords through the task pair rather than
        // through StudentID alone stops a student's completions from other classes leaking into this
        // class's TasksCompleted count, which an earlier version of this query and page did allow, a
        // student enrolled in two classes could show more tasks completed than this class even has.
        public DataTable GenerateStudentStats(int classID)
        {
            DataTable studentStats = new DataTable();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // For each enrolled student, count how many of this class's tasks they have completed.
                string sql = "SELECT u.UserID AS StudentID, u.FullName, " +
                             "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS TasksCompleted, " +
                             "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = @ClassID) AS TotalTasks " +
                             "FROM Users u " +
                             "INNER JOIN ClassEnrolments ce ON u.UserID = ce.StudentID " +
                             "LEFT JOIN HomeworkTasks ht ON ht.ClassID = @ClassID " +
                             "LEFT JOIN CompletionRecords cr ON cr.StudentID = u.UserID AND cr.TaskID = ht.TaskID " +
                             "WHERE ce.ClassID = @ClassID " +
                             "GROUP BY u.UserID, u.FullName " +
                             "ORDER BY u.FullName ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);

                    using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(studentStats);
                    }
                }
            }

            return studentStats;
        }

        /// <summary>
        /// Generates a day by day count of completions for a specific class over the last 30 days.
        /// </summary>
        /// <param name="classID">The class to generate the completion trend for.</param>
        /// <returns>A DataTable with columns CompletionDate, CompletionCount.</returns>
        // Used by the class overview page's Completion Trend graph.
        // DataTable is used here for the same reason as TaskStats and StudentStats above, this result is
        // a computed aggregate (a COUNT grouped by the date portion of MarkedDate) that has no home on
        // any single entity class, not a genuine List<T> of real objects the way PaceTask or
        // CompletionRecord are. The query is capped to the last 30 days rather than showing a class's
        // entire history, a class can accumulate completions over a whole school year, and a chart trying
        // to plot every single day since the class started would either be unreadable or squash recent,
        // more relevant activity down to a sliver, 30 days is enough to show a meaningful recent trend
        // without the chart's width growing unbounded as the year goes on. Grouping is done with
        // CAST(cr.MarkedDate AS DATE) because MarkedDate is a DATETIME with a time component, without the
        // cast every completion marked at a slightly different time of day would form its own group
        // instead of collapsing onto its calendar date.
        public DataTable GenerateCompletionTrend(int classID)
        {
            DataTable trend = new DataTable();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // HomeworkTasks scopes the count to this class, MarkedComplete = 1 excludes records that
                // were unmarked back to incomplete, and the MarkedDate lower bound caps the window to the
                // last 30 days so the chart stays readable.
                string sql = "SELECT CAST(cr.MarkedDate AS DATE) AS CompletionDate, " +
                             "COUNT(*) AS CompletionCount " +
                             "FROM CompletionRecords cr " +
                             "INNER JOIN HomeworkTasks ht ON cr.TaskID = ht.TaskID " +
                             "WHERE ht.ClassID = @ClassID AND cr.MarkedComplete = 1 " +
                             "AND cr.MarkedDate >= @WindowStart " +
                             "GROUP BY CAST(cr.MarkedDate AS DATE) " +
                             "ORDER BY CompletionDate ASC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@WindowStart", DateTime.Today.AddDays(-30));

                    using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(trend);
                    }
                }
            }

            return trend;
        }

        /// <summary>
        /// Calculates the completion percentage for a given count and total.
        /// </summary>
        /// <param name="completionCount">The number of completions.</param>
        /// <param name="totalStudents">The total number of students the count is out of.</param>
        /// <returns>The completion percentage rounded to one decimal place, or 0.0 if totalStudents is zero.</returns>
        // Used when displaying individual percentage values on the statistics page.
        // Returns double rather than int or decimal, an int result would use integer division and
        // truncate the fractional part entirely, for example 1 completed out of 3 tasks would come out as
        // 0 instead of roughly 33.3, hiding real, meaningful partial progress from the teacher. double is
        // sufficient precision for a percentage rounded to one decimal place for display, without the
        // extra overhead decimal would add for a value that is only ever shown, never used in further
        // exact financial style arithmetic. The totalStudents == 0 check exists because a class can
        // legitimately have zero enrolled students (e.g. a brand new class), dividing by zero in that case
        // would throw and crash the entire statistics page rather than simply showing 0%.
        public double CalculatePercentage(int completionCount, int totalStudents)
        {
            // Avoid dividing by zero if the class has no students enrolled
            if (totalStudents == 0) return 0.0;
            return Math.Round((double)completionCount / totalStudents * 100, 1);
        }

        /// <summary>
        /// Builds and returns a complete StatisticsReport for a specific class.
        /// </summary>
        /// <param name="classID">The class to generate the report for.</param>
        /// <returns>A populated StatisticsReport with TotalStudents, TaskStats, StudentStats and CompletionTrend set.</returns>
        // This is the main method called by the teacher's class overview page.
        // Generate() is the single entry point that populates TotalStudents, TaskStats, StudentStats and
        // CompletionTrend together in the correct order, TotalStudents has to be counted first because
        // GenerateTaskStats depends on it already being set on the report before it runs its own query.
        // Calling pages (TeacherClassPage.aspx.cs) call this one static method rather than orchestrating
        // the individual Generate* methods and the student count query themselves, so that ordering
        // dependency lives in exactly one place, and so the page's tables and graphs are always built from
        // one consistent snapshot of the database instead of running the same underlying queries twice.
        public static StatisticsReport Generate(int classID)
        {
            StatisticsReport report = new StatisticsReport();
            report.ClassID = classID;
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // First get the total number of enrolled students for this class
                string countSql = "SELECT COUNT(*) FROM ClassEnrolments WHERE ClassID = @ClassID";

                using (SqlCommand cmd = new SqlCommand(countSql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    report.TotalStudents = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }

            // Generate all three statistics tables using the methods above
            report.TaskStats = report.GenerateTaskStats(classID);
            report.StudentStats = report.GenerateStudentStats(classID);
            report.CompletionTrend = report.GenerateCompletionTrend(classID);

            return report;
        }
    }
}
