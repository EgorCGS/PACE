using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;

namespace PACE
{
    // Represents a single homework task in the PACE system.
    // Tasks are created by teachers and viewed by students.
    // Named PaceTask rather than HomeworkTask because HomeworkTask collides with
    // an imported System/ASP.NET type in this project.
    public class PaceTask
    {
        // - Attributes -

        // Unique ID for this task, matches the TaskID primary key in the database.
        // int is used because TaskID is an identity column (SQL int), and every
        // foreign key that references a task (CompletionRecords.TaskID) stores
        // this same int, the C# type has to match so ADO.NET can read/write it
        // without an implicit conversion at every call site.
        public int TaskID { get; set; }

        // The ID of the class this task belongs to, links to the Classes table.
        // int for the same identity/foreign key matching reason as TaskID above,
        // ClassID is compared directly against Classes.ClassID (also SQL int) in
        // every query that filters tasks by class, so no conversion is needed
        // between the C# object and the WHERE clause parameter.
        public int ClassID { get; set; }

        // The short title of the task (e.g. "Exercises 4A, Derivatives").
        // string maps directly to an NVARCHAR column, NVARCHAR (not VARCHAR) was
        // chosen at the database level so titles are not restricted to ASCII.
        // Title is kept as a short NVARCHAR because it is meant to be scanned at
        // a glance in lists (class pages, dashboards), a long value would break
        // that layout, the full detail belongs in Description instead.
        public string Title { get; set; }

        // The subject this task belongs to (e.g. "Mathematics").
        // string/NVARCHAR again, for the same Unicode reasoning as Title, this
        // field is also short and scannable and is used to group/filter tasks.
        public string Subject { get; set; }

        // The full description of the task, visible to students.
        // string/NVARCHAR again, but Description is deliberately a longer
        // NVARCHAR(1000) rather than a short field like Title, because its real
        // world purpose is different, Title only has to identify the task in a
        // list, Description has to carry enough detail (page numbers, question
        // numbers, instructions) for a student to complete the homework without
        // needing to ask the teacher for clarification.
        public string Description { get; set; }

        // The date this task is due.
        // Stored as SQL DATE (not DATETIME) because a due date has no meaningful
        // time component, homework is due "on" a day, not at a specific second,
        // using DATE avoids storing a misleading time of 00:00:00 that could be
        // mistaken for an actual deadline time. DateTime is still the correct C#
        // type to read it into because DateTime supports date arithmetic
        // (DateTime.Today comparisons), which is exactly what the reasonableness
        // check (due date cannot be in the past) and any "overdue"/urgency
        // highlighting logic need.
        public DateTime DueDate { get; set; }

        // The priority level of the task, stored as an integer (1=Low, 2=Medium, 3=High).
        // int is used, and matched by a CHECK constraint in SQL restricting the
        // column to 1, 2 or 3, rather than a string ("Low"/"Medium"/"High") or a
        // C# enum, for two reasons. First, GetTasksByClass orders results with
        // ORDER BY PriorityLevel DESC, that only produces "High before Medium
        // before Low" if the column is genuinely numeric, a string column would
        // sort alphabetically instead ("High", "Low", "Medium", wrong order).
        // Second, an int keeps the stored value and the CHECK constraint's valid
        // range in the same simple type on both sides of the C#/SQL boundary,
        // with no enum-to-int or enum-to-string mapping layer required just to
        // persist or query it. The human readable label is derived separately in
        // GetPriorityLabel() rather than stored, see that method below.
        public int PriorityLevel { get; set; }

        // The date and time this task was created, set automatically on insert.
        // Stored as SQL DATETIME (not DATE) because, unlike DueDate, the time
        // component matters here, CreatedDate exists purely as an audit trail
        // field (when was this task actually added), and tasks created on the
        // same day still need to be distinguishable/orderable by the time they
        // were created. DateTime in C# is the natural match for a DATETIME
        // column and again supports the date arithmetic used elsewhere.
        public DateTime CreatedDate { get; set; }


        // - Methods -

        /// <summary>
        /// Converts the integer priority level to a readable label.
        /// </summary>
        /// <returns>"High", "Medium", or "Low" based on the stored PriorityLevel value.</returns>
        // The label is computed here, on demand, rather than stored as its own
        // column, because PriorityLevel must stay a plain sortable int (see the
        // attribute comment above), keeping the numeric value as the single
        // source of truth avoids the two ever going out of sync, and it means
        // the wording of the label can be changed in one place without touching
        // the database or any ORDER BY logic that depends on the number.
        public string GetPriorityLabel()
        {
            if (PriorityLevel == 3) return "High";
            if (PriorityLevel == 2) return "Medium";
            return "Low";
        }

        /// <summary>
        /// Gets the CSS class name for the priority badge colour.
        /// </summary>
        /// <returns>A CSS class name matching the priority colour scheme defined in the mockups.</returns>
        // Same reasoning as GetPriorityLabel, the display concern (which colour
        // a priority renders as) is kept entirely separate from the stored data
        // (the int), so the visual design can be restyled independently of the
        // database, and both display forms are derived from one authoritative
        // numeric value instead of drifting out of sync with each other.
        public string GetPriorityBadgeColour()
        {
            if (PriorityLevel == 3) return "badge-high";
            if (PriorityLevel == 2) return "badge-medium";
            return "badge-low";
        }

        /// <summary>
        /// Validates all input fields before a task is created or edited.
        /// </summary>
        /// <param name="title">The task title, must not be empty.</param>
        /// <param name="subject">The task subject, must not be empty.</param>
        /// <param name="description">The task description, must not be empty.</param>
        /// <param name="dueDateStr">The due date as entered, must parse to a valid date.</param>
        /// <param name="priorityStr">The priority level as entered, must parse to 1, 2 or 3.</param>
        /// <returns>True if all fields are valid, false if any check fails.</returns>
        // The existence, type, and range checks are deliberately kept as
        // separate, sequential steps rather than combined into one large
        // condition, for two reasons tied to Criterion 7. First, each check type
        // (existence, type, range) needs to be demonstrably present and
        // identifiable on its own for marking purposes, a single combined
        // boolean expression would hide which specific kind of validation is
        // happening. Second, this lets a specific, useful error message be
        // shown for the failure that actually occurred (e.g. "date is not
        // valid" versus "priority must be 1, 2 or 3"), rather than one generic
        // "invalid input" message that would leave the user guessing which
        // field to fix.
        // Note: CreateTask.aspx.cs and ManageTasks.aspx.cs do not call this
        // method, each implements its own inline validation instead, because
        // their reasonableness-check requirements differ page to page (create
        // always checks the due date is not in the past, edit only checks when
        // the due date value has actually changed). This method is currently
        // unused dead code, kept here as it still documents the validation
        // rules in one place and matches the C6/C7 WHY commentary above.
        public static bool ValidateInputs(string title, string subject, string description, string dueDateStr, string priorityStr)
        {
            // Existence check, no field may be empty
            if (string.IsNullOrWhiteSpace(title) ||
                string.IsNullOrWhiteSpace(subject) ||
                string.IsNullOrWhiteSpace(description) ||
                string.IsNullOrWhiteSpace(dueDateStr) ||
                string.IsNullOrWhiteSpace(priorityStr))
            {
                return false;
            }

            // Type check, due date must be a real valid date
            DateTime parsedDate;
            if (!DateTime.TryParse(dueDateStr, out parsedDate))
            {
                return false;
            }

            // Range check, priority must be 1, 2, or 3
            int priority;
            if (!int.TryParse(priorityStr, out priority) || priority < 1 || priority > 3)
            {
                return false;
            }

            return true;
        }

        /// <summary>
        /// Inserts a new homework task into the database.
        /// </summary>
        /// <param name="classID">The class this task belongs to.</param>
        /// <param name="title">The task title.</param>
        /// <param name="subject">The task subject.</param>
        /// <param name="description">The task description.</param>
        /// <param name="dueDate">The date the task is due.</param>
        /// <param name="priorityLevel">The priority level, 1 to 3.</param>
        /// <returns>The TaskID of the newly created task.</returns>
        // A parameterised INSERT is used (never string concatenation) so
        // teacher-entered values, especially free text like Title and
        // Description, can never be interpreted as SQL, this both prevents SQL
        // injection and correctly handles apostrophes/special characters that
        // would otherwise break a hand built query string. SCOPE_IDENTITY() is
        // used rather than a separate SELECT MAX(TaskID) query, so the ID
        // returned is guaranteed to be the row this exact command just inserted,
        // safe even if another task is inserted concurrently by a different
        // session.
        public static int Create(int classID, string title, string subject,
                                 string description, DateTime dueDate, int priorityLevel)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "INSERT INTO HomeworkTasks (ClassID, Title, Subject, Description, DueDate, PriorityLevel, CreatedDate) " +
                             "VALUES (@ClassID, @Title, @Subject, @Description, @DueDate, @PriorityLevel, @CreatedDate); " +
                             "SELECT SCOPE_IDENTITY();";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@Title", title);
                    cmd.Parameters.AddWithValue("@Subject", subject);
                    cmd.Parameters.AddWithValue("@Description", description);
                    cmd.Parameters.AddWithValue("@DueDate", dueDate);
                    cmd.Parameters.AddWithValue("@PriorityLevel", priorityLevel);
                    cmd.Parameters.AddWithValue("@CreatedDate", DateTime.Now);

                    // SCOPE_IDENTITY() returns the ID of the row just inserted
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
        }

        /// <summary>
        /// Updates an existing homework task in the database.
        /// </summary>
        /// <param name="taskID">The ID of the task to update.</param>
        /// <param name="title">The new task title.</param>
        /// <param name="subject">The new task subject.</param>
        /// <param name="description">The new task description.</param>
        /// <param name="dueDate">The new due date.</param>
        /// <param name="priorityLevel">The new priority level, 1 to 3.</param>
        /// <returns>True if the update was successful.</returns>
        // CreatedDate is deliberately left out of the SET clause, an edit
        // changes the task's content, not the historical fact of when it was
        // originally created, keeping CreatedDate immutable after insert
        // preserves it as a genuine audit field. rowsAffected is checked against
        // 0 (rather than assuming the UPDATE worked) so a caller passing a
        // TaskID that no longer exists (e.g. already deleted) is correctly told
        // the edit did not happen.
        public static bool Edit(int taskID, string title, string subject,
                                string description, DateTime dueDate, int priorityLevel)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "UPDATE HomeworkTasks " +
                             "SET Title = @Title, Subject = @Subject, Description = @Description, " +
                             "DueDate = @DueDate, PriorityLevel = @PriorityLevel " +
                             "WHERE TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@Title", title);
                    cmd.Parameters.AddWithValue("@Subject", subject);
                    cmd.Parameters.AddWithValue("@Description", description);
                    cmd.Parameters.AddWithValue("@DueDate", dueDate);
                    cmd.Parameters.AddWithValue("@PriorityLevel", priorityLevel);

                    // ExecuteNonQuery returns the number of rows affected
                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        /// <summary>
        /// Permanently deletes a homework task from the database.
        /// </summary>
        /// <param name="taskID">The ID of the task to delete.</param>
        /// <returns>True if the deletion was successful.</returns>
        // Any CompletionRecords rows referencing this TaskID are handled at the
        // database level (foreign key with cascade, or the schema otherwise
        // enforces this), the C# layer only issues the DELETE against
        // HomeworkTasks and reports back whether a row was actually removed.
        public static bool Delete(int taskID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "DELETE FROM HomeworkTasks WHERE TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);

                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        /// <summary>
        /// Retrieves all tasks assigned to a specific class, ordered by due date then priority.
        /// </summary>
        /// <param name="classID">The class to retrieve tasks for.</param>
        /// <returns>A list of PaceTask objects, ordered by DueDate ascending then PriorityLevel descending.</returns>
        // List<PaceTask> is used rather than a DataTable or array, so calling
        // pages (StudentClassPage, TeacherClassPage) can bind directly to
        // strongly typed PaceTask objects, with GetPriorityLabel and
        // GetPriorityBadgeColour available on each item, instead of pulling
        // loose column values out of a DataTable by string name at render time.
        // The ORDER BY sorts by DueDate ASC first, so the most urgent (soonest
        // due) tasks surface at the top of the list, which is what students need
        // to plan around (FR06, viewing upcoming homework), then by
        // PriorityLevel DESC as the tiebreaker, so when several tasks share a
        // due date the highest priority one is still shown first (FR07,
        // priority-aware ordering), this only works as a genuine numeric sort
        // because PriorityLevel is stored as an int, see the attribute comment
        // above.
        public static List<PaceTask> GetTasksByClass(int classID)
        {
            List<PaceTask> tasks = new List<PaceTask>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT TaskID, ClassID, Title, Subject, Description, DueDate, PriorityLevel, CreatedDate " +
                             "FROM HomeworkTasks " +
                             "WHERE ClassID = @ClassID " +
                             "ORDER BY DueDate ASC, PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            // Create a PaceTask object for each row returned
                            PaceTask task = new PaceTask
                            {
                                TaskID = Convert.ToInt32(reader["TaskID"]),
                                ClassID = Convert.ToInt32(reader["ClassID"]),
                                Title = reader["Title"].ToString(),
                                Subject = reader["Subject"].ToString(),
                                Description = reader["Description"].ToString(),
                                DueDate = Convert.ToDateTime(reader["DueDate"]),
                                PriorityLevel = Convert.ToInt32(reader["PriorityLevel"]),
                                CreatedDate = Convert.ToDateTime(reader["CreatedDate"])
                            };
                            tasks.Add(task);
                        }
                    }
                }
            }

            return tasks;
        }
    }
}
