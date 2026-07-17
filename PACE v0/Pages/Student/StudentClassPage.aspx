<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="StudentClassPage.aspx.cs" Inherits="PACE.StudentClassPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Class Tasks</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <style>
        :root {
            --bg:#ddeaf7; --sidebar:#4a6fa5; --topbar:#5b7db8; --hero-dark:#3a5a8c;
            --text-dark:#1a2d42; --text-muted:#7a9fbe; --white:#ffffff; --border:#c5daf0;
            --red:#d95c5c; --red-bg:#fdf0f0; --red-border:#f0b8b8;
            --orange:#d4882a; --orange-bg:#fef7ee; --orange-border:#f0d0a0;
            --green:#3a9e6e; --green-bg:#eef8f3; --green-border:#a8d9c0;
            --sidebar-w:258px; --topbar-h:58px; --filterbar-h:52px;
            --shadow:0 2px 8px rgba(74,111,165,0.10);
        }
        *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
        a { text-decoration:none; }
        html, body { font-family:'DM Sans',sans-serif; background:var(--bg); color:var(--text-dark); font-size:14px; }

        .sidebar { position:fixed; left:0; top:0; bottom:0; width:var(--sidebar-w); background:var(--sidebar); display:flex; flex-direction:column; z-index:300; overflow-y:auto; }
        .sidebar-logo { padding:24px 20px 20px; border-bottom:1px solid rgba(255,255,255,0.12); }
        .logo-title { font-size:22px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .logo-sub { font-size:11px; color:rgba(255,255,255,0.55); margin-top:2px; }
        .sidebar-nav { flex:1; padding:12px 0; }
        .nav-section-label { padding:14px 20px 5px; font-size:10.5px; font-weight:600; letter-spacing:0.8px; text-transform:uppercase; color:rgba(255,255,255,0.38); }
        .nav-item { display:flex; align-items:center; gap:10px; padding:9px 16px 9px 20px; margin:1px 8px; border-radius:8px; color:rgba(255,255,255,0.70); font-size:13.5px; text-decoration:none; transition:background 0.15s,color 0.15s; }
        .nav-item:hover { background:rgba(255,255,255,0.12); color:#fff; }
        .nav-item.active { background:rgba(255,255,255,0.18); color:#fff; font-weight:600; }
        .nav-item i { font-size:17px; flex-shrink:0; }
        .nav-item-label { flex:1; }
        .nav-badge { font-size:11px; font-weight:700; background:rgba(255,255,255,0.22); color:#fff; padding:1px 7px; border-radius:20px; }
        .nav-badge.overdue { background:rgba(212,136,42,0.85); }
        .sidebar-user { padding:14px 16px; border-top:1px solid rgba(255,255,255,0.12); display:flex; align-items:center; gap:10px; }
        .user-avatar { width:36px; height:36px; border-radius:50%; background:rgba(255,255,255,0.22); color:#fff; font-size:13px; font-weight:600; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .user-info { flex:1; min-width:0; }
        .user-name { font-size:13px; font-weight:600; color:#fff; }
        .user-role { font-size:11px; color:rgba(255,255,255,0.50); }
        .btn-logout { background:none; border:none; color:rgba(255,255,255,0.45); cursor:pointer; padding:4px; border-radius:6px; transition:color 0.15s,background 0.15s; text-decoration:none; }
        .btn-logout:hover { color:#fff; background:rgba(255,255,255,0.12); }
        .btn-logout i { font-size:18px; display:block; }

        .main { margin-left:var(--sidebar-w); min-height:100vh; display:flex; flex-direction:column; }
        .topbar { position:sticky; top:0; z-index:200; height:var(--topbar-h); background:var(--topbar); display:flex; align-items:center; padding:0 28px; box-shadow:0 2px 10px rgba(58,90,140,0.18); }
        .breadcrumb { display:flex; align-items:center; gap:6px; font-size:13px; color:rgba(255,255,255,0.65); }
        .breadcrumb a { color:rgba(255,255,255,0.65); }
        .breadcrumb .sep { opacity:0.45; font-size:12px; }
        .breadcrumb .current { color:#fff; font-weight:500; }
        .hero { background:linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%); padding:30px 28px 28px; }
        .hero-title { font-size:28px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .hero-sub { font-size:14px; color:rgba(255,255,255,0.62); margin-top:4px; }

        /* Sticky filter bar */
        .filter-bar { position:sticky; top:var(--topbar-h); z-index:150; background:var(--white); border-bottom:1px solid var(--border); box-shadow:0 2px 8px rgba(74,111,165,0.08); padding:0 28px; height:var(--filterbar-h); display:flex; align-items:center; gap:10px; }
        .filter-chips { display:flex; gap:6px; flex:1; }
        /* appearance:none strips native button chrome, which otherwise renders with its own
           box metrics (line-height, internal insets) layered on top of this padding, the same
           issue .sort-select below is already reset for. line-height:1 then makes the chip's
           vertical size fully determined by padding, not by an inherited or native line-height. */
        .chip { padding:5px 14px; border-radius:20px; font-size:13px; font-weight:500; line-height:1; cursor:pointer; border:1.5px solid var(--border); color:var(--text-muted); background:#fff; appearance:none; -webkit-appearance:none; transition:all 0.15s; user-select:none; font-family:'DM Sans',sans-serif; }
        .chip:hover { border-color:var(--topbar); color:var(--topbar); }
        /* Active state uses background/border/color only, not font-weight, so the chip's
           rendered text width never changes on toggle. A 500->600 weight swap on DM Sans
           widens the glyphs enough to shift the whole flex row on activation. */
        .chip.active { background:var(--topbar); border-color:var(--topbar); color:#fff; }
        .filter-right { display:flex; align-items:center; gap:8px; }
        .search-wrap { position:relative; display:flex; align-items:center; }
        .search-wrap i { position:absolute; left:10px; color:var(--text-muted); font-size:15px; pointer-events:none; }
        .search-input { padding:6px 12px 6px 32px; border-radius:8px; border:1.5px solid var(--border); background:var(--bg); font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); width:200px; outline:none; transition:border-color 0.15s; }
        .search-input:focus { border-color:var(--topbar); background:#fff; }
        .search-input::placeholder { color:var(--text-muted); }
        /* Fixed width, not auto: a native <select> otherwise resizes to fit whichever
           option is currently selected, which would shift the search box to its left
           since .filter-chips (flex:1) absorbs whatever width .filter-right does not use. */
        .sort-select { width:148px; padding:6px 28px 6px 10px; border-radius:8px; border:1.5px solid var(--border); background:var(--bg) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%237a9fbe' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E") no-repeat right 8px center; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); outline:none; appearance:none; cursor:pointer; transition:border-color 0.15s; }
        .sort-select:focus { border-color:var(--topbar); }
        /* min-width reserves space for the longest realistic count text ("23 of 24 tasks")
           so filtering/searching does not resize .filter-right and shift the search box,
           which sits to its left inside the same flex row (.filter-chips is flex:1 and
           absorbs whatever width .filter-right does not use). */
        .filter-count { font-size:12.5px; color:var(--text-muted); white-space:nowrap; min-width:100px; text-align:right; }

        .content { padding:24px 28px 40px; display:flex; flex-direction:column; gap:20px; }
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }
        .card-header { display:flex; align-items:center; gap:10px; padding:16px 20px 14px; border-bottom:1px solid var(--border); }
        .card-header-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .card-header-title { font-size:15px; font-weight:600; flex:1; }
        .card-header-count { font-size:13px; color:var(--text-muted); }
        .table-card { overflow:hidden; }
        .task-table { width:100%; border-collapse:collapse; }
        .task-table thead th { padding:11px 14px; text-align:left; font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); background:var(--bg); border-bottom:1px solid var(--border); }
        .task-table thead th:first-child { padding-left:18px; }
        .task-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.12s; }
        .task-table tbody tr:last-child { border-bottom:none; }
        .task-table tbody tr:nth-child(even) { background:#f7f9fd; }
        .task-table tbody tr:hover { background:#eef3fb; }
        .task-table td { padding:11px 14px; vertical-align:middle; }
        .task-table td:first-child { padding-left:18px; }
        .task-name { font-size:13.5px; font-weight:600; }
        .task-desc { font-size:12px; color:var(--text-muted); margin-top:2px; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
        .due-main { font-size:13px; font-weight:500; }
        .due-urgency { font-size:11px; font-weight:500; margin-top:1px; }
        .due-red { color:var(--red); } .due-orange { color:var(--orange); } .due-green { color:var(--green); }
        .badge { display:inline-flex; align-items:center; padding:2px 8px; border-radius:20px; font-size:11.5px; font-weight:500; border:1px solid; white-space:nowrap; }
        .badge-high     { color:var(--red);    background:var(--red-bg);    border-color:var(--red-border); }
        .badge-med      { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-low      { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .badge-pending  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-complete { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .btn-view { display:inline-flex; align-items:center; gap:4px; padding:5px 12px; border-radius:7px; background:var(--topbar); color:#fff; font-size:12px; font-weight:500; text-decoration:none; transition:background 0.15s; }
        .btn-view:hover { background:var(--hero-dark); }
        .btn-view i { font-size:14px; }
        .no-results { padding:36px 20px; text-align:center; color:var(--text-muted); font-size:13.5px; }
        .empty-state { padding:48px 20px; text-align:center; color:var(--text-muted); }

        /* Class progress stats card */
        .stats-body { padding:16px 20px 18px; display:flex; flex-direction:column; gap:16px; }
        .stats-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:12px; }
        .stat-tile { background:var(--bg); border:1px solid var(--border); border-radius:10px; padding:12px 14px; text-align:center; }
        .stat-value { font-size:22px; font-weight:700; color:var(--text-dark); }
        .stat-label { font-size:11px; font-weight:600; letter-spacing:0.5px; text-transform:uppercase; color:var(--text-muted); margin-top:2px; }
        .progress-label-row { display:flex; justify-content:space-between; margin-bottom:4px; font-size:13px; }
        .progress-subj { font-weight:500; }
        .progress-pct { font-weight:600; color:var(--text-muted); }
        .progress-track { height:7px; border-radius:10px; background:var(--bg); border:1px solid var(--border); overflow:hidden; }
        .progress-fill { height:100%; border-radius:10px; background:linear-gradient(90deg,var(--sidebar),var(--topbar)); }
        .progress-fill.green  { background:linear-gradient(90deg,#2d8a5f,var(--green)); }
        .progress-fill.orange { background:linear-gradient(90deg,#b86e10,var(--orange)); }
        .progress-fill.zero   { background:var(--border); }
    </style>
</head>
<body>
    <form id="frmClassPage" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Main</div>
                <a class="nav-item" href="StudentDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">My Dashboard</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class='<%# GetNavClass(Eval("ClassID")) %>' href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-book"></i>
                            <span class="nav-item-label"><%# Eval("ClassName") %></span>
                            <%# Convert.ToInt32(Eval("PendingCount")) > 0
                                ? "<span class='nav-badge" + (Convert.ToInt32(Eval("OverdueCount")) > 0 ? " overdue" : "") + "'>" + Eval("PendingCount") + "</span>"
                                : "" %>
                        </a>
                    </ItemTemplate>
                </asp:Repeater>
            </nav>
            <div class="sidebar-user">
                <div class="user-avatar"><%= GetInitials() %></div>
                <div class="user-info">
                    <div class="user-name"><%= Session["FullName"] %></div>
                    <div class="user-role">Student</div>
                </div>
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn-logout" OnClick="btnLogout_Click"><i class="ti ti-logout"></i></asp:LinkButton>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="breadcrumb">
                    <a href="StudentDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <a href="StudentDashboard.aspx">My Dashboard</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current"><asp:Label ID="lblBreadcrumb" runat="server" /></span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title"><asp:Label ID="lblHeroTitle" runat="server" /></div>
                <div class="hero-sub">All homework tasks for this class, ordered by due date and priority.</div>
            </div>

            <div class="filter-bar">
                <div class="filter-chips">
                    <button type="button" class="chip active" data-filter="pending"  onclick="setChip(this)">Pending</button>
                    <button type="button" class="chip"        data-filter="complete" onclick="setChip(this)">Completed</button>
                    <button type="button" class="chip"        data-filter="all"      onclick="setChip(this)">All Tasks</button>
                    <button type="button" class="chip"        data-filter="high"     onclick="setChip(this)">High Priority</button>
                    <button type="button" class="chip"        data-filter="overdue"  onclick="setChip(this)">Overdue</button>
                </div>
                <div class="filter-right">
                    <div class="search-wrap">
                        <i class="ti ti-search"></i>
                        <input type="text" id="searchInput" class="search-input" placeholder="Search tasks..." oninput="applyFilters()" />
                    </div>
                    <select id="sortSelect" class="sort-select" onchange="applyFilters()">
                        <option value="due">Sort: Due Date</option>
                        <option value="priority">Sort: Priority</option>
                        <option value="status">Sort: Status</option>
                    </select>
                    <span class="filter-count" id="filterCount"></span>
                </div>
            </div>

            <div class="content">
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-chart-bar" style="color:#3a9e6e;font-size:17px;"></i></div>
                        <span class="card-header-title">Class Progress</span>
                    </div>
                    <div class="stats-body">
                        <div class="stats-grid">
                            <div class="stat-tile">
                                <div class="stat-value"><asp:Label ID="lblStatTotal" runat="server" /></div>
                                <div class="stat-label">Total Tasks</div>
                            </div>
                            <div class="stat-tile">
                                <div class="stat-value" style="color:var(--green);"><asp:Label ID="lblStatCompleted" runat="server" /></div>
                                <div class="stat-label">Completed</div>
                            </div>
                            <div class="stat-tile">
                                <div class="stat-value" style="color:var(--orange);"><asp:Label ID="lblStatPending" runat="server" /></div>
                                <div class="stat-label">Pending</div>
                            </div>
                        </div>
                        <div>
                            <div class="progress-label-row">
                                <span class="progress-subj">Completion</span>
                                <span class="progress-pct"><%= GetStatsPctDisplay() %></span>
                            </div>
                            <div class="progress-track">
                                <div class="progress-fill <%= GetStatsPctClass() %>" style="width:<%= GetStatsPctWidth() %>%"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card table-card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                        <span class="card-header-title">Tasks</span>
                        <span class="card-header-count"><asp:Label ID="lblTaskCount" runat="server" /> tasks</span>
                    </div>

                    <asp:Repeater ID="rptTasks" runat="server">
                        <HeaderTemplate>
                            <table class="task-table">
                                <thead>
                                    <tr><th>Task</th><th>Due Date</th><th>Priority</th><th>Status</th><th>Action</th></tr>
                                </thead>
                                <tbody id="taskTbody">
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class="task-row"
                                data-status='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "complete" : "pending" %>'
                                data-priority='<%# Eval("PriorityLevel") %>'
                                data-title='<%# Eval("Title").ToString().ToLower().Replace("'","") %>'
                                data-due='<%# Convert.ToDateTime(Eval("DueDate")).ToString("yyyy-MM-dd") %>'
                                data-overdue='<%# Convert.ToDateTime(Eval("DueDate")).Date < DateTime.Today ? "1" : "0" %>'>
                                <td>
                                    <div class="task-name"><%# Eval("Title") %></div>
                                    <div class="task-desc"><%# Eval("Description") %></div>
                                </td>
                                <td>
                                    <div class="due-main"><%# Convert.ToDateTime(Eval("DueDate")).ToString("d MMM yyyy") %></div>
                                    <div class="due-urgency <%# GetUrgencyClass(Eval("DueDate")) %>"><%# GetUrgencyText(Eval("DueDate")) %></div>
                                </td>
                                <td><%# GetPriorityBadge(Eval("PriorityLevel")) %></td>
                                <td><%# GetStatusBadge(Eval("MarkedComplete")) %></td>
                                <td><a class="btn-view" href='TaskDetail.aspx?TaskID=<%# Eval("TaskID") %>'><i class="ti ti-eye"></i> View</a></td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>

                    <div id="noResults" class="no-results" style="display:none;">No tasks match your search or filter.</div>
                    <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                        <div class="empty-state">No tasks assigned to this class yet.</div>
                    </asp:Panel>
                </div>
            </div>
        </div>

    </form>

    <script>
        // Pending is the default view since that is what a student needs to act on first.
        var activeFilter = 'pending';

        /**
         * Marks the clicked filter chip active, deactivates the rest, and re-applies
         * the task filters using the chip's data-filter value.
         * @param {HTMLElement} el - The chip element that was clicked.
         */
        function setChip(el) {
            document.querySelectorAll('.chip').forEach(function(c) { c.classList.remove('active'); });
            el.classList.add('active');
            activeFilter = el.dataset.filter;
            applyFilters();
        }

        /**
         * Filters, searches, sorts, and re-renders the visible task rows based on the
         * active chip, the search box, and the sort dropdown.
         */
        function applyFilters() {
            var search = document.getElementById('searchInput').value.toLowerCase();
            var sortBy = document.getElementById('sortSelect').value;
            var tbody  = document.getElementById('taskTbody');
            if (!tbody) return;

            var rows = Array.from(document.querySelectorAll('.task-row'));
            var visibleCount = 0;

            rows.forEach(function(row) {
                var show = true;
                if (activeFilter === 'pending'  && row.dataset.status !== 'pending')  show = false;
                if (activeFilter === 'complete' && row.dataset.status !== 'complete') show = false;
                if (activeFilter === 'high'     && row.dataset.priority !== '3')      show = false;
                if (activeFilter === 'overdue'  && row.dataset.overdue !== '1')       show = false;
                if (search && !row.dataset.title.includes(search)) show = false;
                row.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });

            // Re-sort visible rows.
            // "due" is both the dropdown's default option and the page-load state, so it
            // doubles as the default row order. Completion status is sorted first (pending
            // before completed) so a completed task never outranks a pending one by date or
            // priority alone, matching the same rule applied to the initial C# ORDER BY in
            // StudentClassPage.aspx.cs.
            var visible = rows.filter(function(r) { return r.style.display !== 'none'; });
            visible.sort(function(a, b) {
                if (sortBy === 'due') {
                    if (a.dataset.status !== b.dataset.status) return a.dataset.status === 'pending' ? -1 : 1;
                    var dueCompare = a.dataset.due.localeCompare(b.dataset.due);
                    if (dueCompare !== 0) return dueCompare;
                    return parseInt(b.dataset.priority) - parseInt(a.dataset.priority);
                }
                if (sortBy === 'priority') return parseInt(b.dataset.priority) - parseInt(a.dataset.priority);
                if (sortBy === 'status')   return b.dataset.status.localeCompare(a.dataset.status);
                return 0;
            });
            visible.forEach(function(r) { tbody.appendChild(r); });

            var total = rows.length;
            document.getElementById('filterCount').textContent = visibleCount === total
                ? total + ' tasks'
                : visibleCount + ' of ' + total + ' tasks';
            document.getElementById('noResults').style.display = visibleCount === 0 ? 'block' : 'none';
        }

        window.addEventListener('load', applyFilters);
    </script>
</body>
</html>