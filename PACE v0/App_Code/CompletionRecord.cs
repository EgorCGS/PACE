using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;

namespace PACE
{
    // Represents a single completion record in the PACE system.
    // A completion record tracks whether a specific student has completed a specific task.
    public class CompletionRecord
    {
        // - Attributes -

        // Unique ID for this completion record, matches the CompletionID primary key in the database.
        // int is used because CompletionID is an identity column (SQL int), matching the identity/foreign
        // key reasoning used throughout the other App_Code classes, the C# type has to match what ADO.NET
        // reads and writes so no implicit conversion is needed at any call site.
        public int CompletionID { get; set; }

        // The ID of the task this record applies to, links to the HomeworkTasks table.
        // int for the same identity/foreign key matching reason as CompletionID above, TaskID is compared
        // directly against HomeworkTasks.TaskID (also SQL int) in every query in this class, so no
        // conversion is needed between the C# object and the SQL parameter.
        public int TaskID { get; set; }

        // The ID of the student this record applies to, links to the Users table.
        // int for the same reason as TaskID, StudentID is compared directly against Users.UserID, keeping
        // both sides of the foreign key in the same simple type.
        public int StudentID { get; set; }

        // Whether the teacher has marked this student as having completed the task.
        // Stored as a BIT in the database and bool in C#, completion is a genuinely binary state, a
        // student either has or has not been marked complete for a task, there is no third state and no
        // meaningful degree of completion to represent. A status string (e.g. "Complete"/"Incomplete")
        // was deliberately not used, it would allow invalid values to creep in (typos, inconsistent
        // casing) that a BIT column cannot, and every check against this field throughout the app
        // (IsComplete, the completion grid, statistics counts) is a true/false test, so bool is the
        // exact match for how the value is actually used, with no string comparison or parsing required.
        public bool MarkedComplete { get; set; }

        // The date and time the teacher marked this record, null if not yet marked.
        // DateTime? (nullable) is used rather than a plain DateTime specifically because a completion
        // record can exist in an unmarked state, MarkedComplete = 0, with no meaningful marked date at
        // all, a plain DateTime would force some placeholder value (e.g. DateTime.MinValue or the
        // record's creation time) to be stored in its place, which would misrepresent an event that has
        // not actually happened as though it had. Null instead means exactly what it says, this record has
        // never been marked complete. This is also why UnmarkComplete() explicitly sets MarkedDate back to
        // NULL rather than leaving the old timestamp in place, once a teacher unmarks a task, the previous
        // marked date is no longer a true fact about the record's current state and must not linger as if
        // it were.
        public DateTime? MarkedDate { get; set; }

        // - Methods -

        /// <summary>
        /// Checks whether a completion record already exists for a specific task and student.
        /// </summary>
        /// <param name="taskID">The task to check.</param>
        /// <param name="studentID">The student to check.</param>
        /// <returns>True if a completion record already exists for this task/student pair.</returns>
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

        /// <summary>
        /// Marks a specific student as having completed a specific task, inserting or updating
        /// the completion record as needed.
        /// </summary>
        /// <param name="taskID">The task being marked complete.</param>
        /// <param name="studentID">The student being marked complete.</param>
        /// <returns>True if the operation was successful.</returns>
        // This INSERT-if-missing-else-UPDATE pattern (an upsert) exists because CompletionRecords has a
        // unique constraint on (TaskID, StudentID), one student can only ever have a single completion
        // record per task, not a growing history of rows every time a teacher toggles the checkbox. A
        // plain unconditional INSERT would violate that unique constraint the second time the same
        // task/student pair was marked, so RecordExists() is checked first to decide which SQL statement
        // is actually safe to run, keeping exactly one row per task/student pairing at all times.
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

        /// <summary>
        /// Unmarks a specific student's completion record for a specific task.
        /// </summary>
        /// <param name="taskID">The task being unmarked.</param>
        /// <param name="studentID">The student being unmarked.</param>
        /// <returns>True if the operation was successful.</returns>
        // Used when a teacher needs to correct a mistaken completion mark.
        // This is an UPDATE, not a DELETE, the row itself (and its unique TaskID/StudentID pairing) stays
        // in place, only the two fields that represent completion status change, MarkedComplete goes back
        // to 0 and MarkedDate is explicitly set to NULL rather than left holding a stale timestamp, so the
        // record's stored state always matches what MarkedDate's nullability is meant to represent, no
        // marked date should exist once a record is no longer marked complete.
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

        /// <summary>
        /// Retrieves all completion records for a specific task.
        /// </summary>
        /// <param name="taskID">The task to retrieve completion records for.</param>
        /// <returns>A list of CompletionRecord objects for this task.</returns>
        // Used by the teacher's completion grid to show which students have completed a task.
        // List<CompletionRecord> is used rather than a DataTable, matching the same typed-object
        // consistency reasoning used by PaceTask.GetTasksByClass and SchoolClass's Get methods, so callers
        // work with real CompletionRecord properties instead of pulling values out of a result set by
        // string column name. This is also the data StatisticsReport.GenerateTaskStats effectively
        // aggregates in SQL, this typed list version exists for the completion grid's row-by-row rendering
        // need, while the statistics page needs pre-aggregated counts and percentages instead, hence that
        // class uses DataTable for its own different purpose, see StatisticsReport.cs.
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

        /// <summary>
        /// Checks whether a specific student has completed a specific task.
        /// </summary>
        /// <param name="taskID">The task to check.</param>
        /// <param name="studentID">The student to check.</param>
        /// <returns>True if the student has been marked complete for this task, false otherwise.</returns>
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
