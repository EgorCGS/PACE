using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace PACE
{
    // Represents the statistics report for a specific class.
    // Used by the teacher's statistics dashboard to show completion rates
    // across all tasks and all enrolled students.
    public class StatisticsReport
    {
        // - Attributes -

        // The ID of the class this report is generated for
        public int ClassID { get; set; }

        // The total number of students enrolled in the class
        public int TotalStudents { get; set; }

        // A table of task level statistics, one row per task.
        // Columns: TaskID, Title, CompletionCount, TotalStudents, Percentage
        public DataTable TaskStats { get; set; }

        // A table of student level statistics, one row per student.
        // Columns: StudentID, FullName, TasksCompleted, TotalTasks
        public DataTable StudentStats { get; set; }

        // - Methods -

        // Generates the task level statistics table for a specific class.
        // Shows how many students have completed each task and the completion percentage.
        public DataTable GenerateTaskStats(int classID)
        {
            DataTable taskStats = new DataTable();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // For each task in the class, count how many students have MarkedComplete = 1.
                // LEFT JOIN ensures tasks with zero completions still appear in the results.
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

        // Generates the student level statistics table for a specific class.
        // Shows how many tasks each student has completed out of the total assigned.
        public DataTable GenerateStudentStats(int classID)
        {
            DataTable studentStats = new DataTable();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // For each enrolled student, count how many tasks they have completed.
                // LEFT JOIN ensures students with zero completions still appear in the results.
                string sql = "SELECT u.UserID AS StudentID, u.FullName, " +
                             "COUNT(CASE WHEN cr.MarkedComplete = 1 THEN 1 END) AS TasksCompleted, " +
                             "(SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = @ClassID) AS TotalTasks " +
                             "FROM Users u " +
                             "INNER JOIN ClassEnrolments ce ON u.UserID = ce.StudentID " +
                             "LEFT JOIN CompletionRecords cr ON u.UserID = cr.StudentID " +
                             "INNER JOIN HomeworkTasks ht ON cr.TaskID = ht.TaskID AND ht.ClassID = @ClassID " +
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

        // Calculates the completion percentage for a given count and total.
        // Used when displaying individual percentage values on the statistics page.
        public double CalculatePercentage(int completionCount, int totalStudents)
        {
            // Avoid dividing by zero if the class has no students enrolled
            if (totalStudents == 0) return 0.0;
            return Math.Round((double)completionCount / totalStudents * 100, 1);
        }

        // Builds and returns a complete StatisticsReport for a specific class.
        // This is the main method called by the teacher's statistics page.
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

            // Generate both statistics tables using the methods above
            report.TaskStats = report.GenerateTaskStats(classID);
            report.StudentStats = report.GenerateStudentStats(classID);

            return report;
        }
    }
}