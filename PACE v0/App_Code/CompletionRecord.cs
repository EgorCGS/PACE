using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace PACE
{
    // Represents a single completion record in the PACE system.
    // A completion record tracks whether a specific student has completed a specific task.
    public class CompletionRecord
    {
        // - Attributes -

        // Unique ID for this completion record, matches the CompletionID primary key in the database
        public int CompletionID { get; set; }

        // The ID of the task this record applies to, links to the PaceTasks table
        public int TaskID { get; set; }

        // The ID of the student this record applies to, links to the Users table
        public int StudentID { get; set; }

        // Whether the teacher has marked this student as having completed the task.
        // Stored as a BIT in the database (0 = not complete, 1 = complete)
        public bool MarkedComplete { get; set; }

        // The date and time the teacher marked this record, null if not yet marked
        public DateTime? MarkedDate { get; set; }

        // - Methods -

        // Checks whether a completion record already exists for a specific task and student.
        // Used before inserting to decide whether to INSERT or UPDATE.
        public static bool RecordExists(int taskID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT COUNT(*) FROM CompletionRecords " +
                             "WHERE TaskID = @TaskID AND StudentID = @StudentID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);

                    int count = Convert.ToInt32(cmd.ExecuteScalar());
                    return count > 0;
                }
            }
        }

        // Marks a specific student as having completed a specific task.
        // If a record already exists it updates it, otherwise it inserts a new one.
        // Returns true if the operation was successful.
        public static bool MarkComplete(int taskID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql;

                if (RecordExists(taskID, studentID))
                {
                    // Record exists, update it to marked complete
                    sql = "UPDATE CompletionRecords " +
                          "SET MarkedComplete = 1, MarkedDate = @MarkedDate " +
                          "WHERE TaskID = @TaskID AND StudentID = @StudentID";
                }
                else
                {
                    // No record exists, insert a new one
                    sql = "INSERT INTO CompletionRecords (TaskID, StudentID, MarkedComplete, MarkedDate) " +
                          "VALUES (@TaskID, @StudentID, 1, @MarkedDate)";
                }

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);
                    cmd.Parameters.AddWithValue("@MarkedDate", DateTime.Now);

                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        // Unmarks a specific student's completion record for a specific task.
        // Used when a teacher needs to correct a mistaken completion mark.
        // Returns true if the operation was successful.
        public static bool UnmarkComplete(int taskID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "UPDATE CompletionRecords " +
                             "SET MarkedComplete = 0, MarkedDate = NULL " +
                             "WHERE TaskID = @TaskID AND StudentID = @StudentID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);

                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        // Retrieves all completion records for a specific task.
        // Used by the teacher's completion grid to show which students have completed a task.
        public static List<CompletionRecord> GetRecordsByTask(int taskID)
        {
            List<CompletionRecord> records = new List<CompletionRecord>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT CompletionID, TaskID, StudentID, MarkedComplete, MarkedDate " +
                             "FROM CompletionRecords " +
                             "WHERE TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            CompletionRecord record = new CompletionRecord
                            {
                                CompletionID = Convert.ToInt32(reader["CompletionID"]),
                                TaskID = Convert.ToInt32(reader["TaskID"]),
                                StudentID = Convert.ToInt32(reader["StudentID"]),
                                MarkedComplete = Convert.ToBoolean(reader["MarkedComplete"]),
                                MarkedDate = reader["MarkedDate"] == DBNull.Value
                                                 ? (DateTime?)null
                                                 : Convert.ToDateTime(reader["MarkedDate"])
                            };
                            records.Add(record);
                        }
                    }
                }
            }

            return records;
        }

        // Checks whether a specific student has completed a specific task.
        // Used on the student dashboard to show the correct status for each task.
        public static bool IsComplete(int taskID, int studentID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT MarkedComplete FROM CompletionRecords " +
                             "WHERE TaskID = @TaskID AND StudentID = @StudentID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@StudentID", studentID);

                    object result = cmd.ExecuteScalar();

                    // If no record exists at all, the task is not complete
                    if (result == null || result == DBNull.Value)
                        return false;

                    return Convert.ToBoolean(result);
                }
            }
        }
    }
}