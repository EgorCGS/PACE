<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="StudentDashboard.aspx.cs" Inherits="PACE.StudentDashboard" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - My Dashboard</title>
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
        /* Default badge: muted white pill */
        .nav-badge { font-size:11px; font-weight:700; background:rgba(255,255,255,0.22); color:#fff; padding:1px 7px; border-radius:20px; }
        /* Overdue badge: orange tint to signal urgency */
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
        .breadcrumb { font-size:13px; color:rgba(255,255,255,0.65); display:flex; align-items:center; gap:6px; }
        .breadcrumb .sep { opacity:0.45; font-size:12px; }
        .breadcrumb .current { color:#fff; font-weight:500; }
        .hero { background:linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%); padding:30px 28px 28px; }
        .hero-title { font-size:28px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .hero-sub { font-size:14px; color:rgba(255,255,255,0.62); margin-top:4px; }

        /* Sticky filter bar sits below topbar */
        .filter-bar { position:sticky; top:var(--topbar-h); z-index:150; background:var(--white); border-bottom:1px solid var(--border); box-shadow:0 2px 8px rgba(74,111,165,0.08); padding:0 28px; height:var(--filterbar-h); display:flex; align-items:center; gap:10px; }
        .filter-chips { display:flex; gap:6px; flex:1; }
        .chip { padding:5px 14px; border-radius:20px; font-size:13px; font-weight:500; cursor:pointer; border:1.5px solid var(--border); color:var(--text-muted); background:#fff; transition:all 0.15s; user-select:none; font-family:'DM Sans',sans-serif; }
        .chip:hover { border-color:var(--topbar); color:var(--topbar); }
        .chip.active { background:var(--topbar); border-color:var(--topbar); color:#fff; font-weight:600; }
        .filter-right { display:flex; align-items:center; gap:8px; }
        .search-wrap { position:relative; display:flex; align-items:center; }
        .search-wrap i { position:absolute; left:10px; color:var(--text-muted); font-size:15px; pointer-events:none; }
        .search-input { padding:6px 12px 6px 32px; border-radius:8px; border:1.5px solid var(--border); background:var(--bg); font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); width:200px; outline:none; transition:border-color 0.15s; }
        .search-input:focus { border-color:var(--topbar); background:#fff; }
        .search-input::placeholder { color:var(--text-muted); }
        .sort-select { padding:6px 28px 6px 10px; border-radius:8px; border:1.5px solid var(--border); background:var(--bg) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%237a9fbe' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E") no-repeat right 8px center; font-family:'DM Sans',sans-serif; font-size:13px; color:var(--text-dark); outline:none; appearance:none; cursor:pointer; transition:border-color 0.15s; }
        .sort-select:focus { border-color:var(--topbar); }
        .filter-count { font-size:12.5px; color:var(--text-muted); white-space:nowrap; }

        .content { padding:24px 28px 40px; display:flex; flex-direction:column; gap:24px; }
        .section-label { font-size:10.5px; font-weight:600; letter-spacing:0.9px; text-transform:uppercase; color:var(--text-muted); margin-bottom:10px; }

        /* Urgent cards */
        .urgent-grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
        .urgent-card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); overflow:hidden; }
        .urgent-inner { padding:16px 18px; border-left:4px solid var(--red); display:flex; flex-direction:column; gap:8px; }
        .urgent-inner.orange { border-left-color:var(--orange); }
        .urgent-title { font-size:14px; font-weight:700; color:var(--text-dark); }
        .urgent-meta { display:flex; gap:12px; font-size:12px; color:var(--text-muted); flex-wrap:wrap; }
        .urgent-meta span { display:flex; align-items:center; gap:4px; }
        .urgent-meta i { font-size:13px; }
        .urgent-footer { padding:10px 18px; border-top:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
        .urgent-label { font-size:12px; font-weight:600; display:flex; align-items:center; gap:4px; }

        /* Badges */
        .badge { display:inline-flex; align-items:center; padding:2px 8px; border-radius:20px; font-size:11.5px; font-weight:500; border:1px solid; white-space:nowrap; }
        .badge-high     { color:var(--red);    background:var(--red-bg);    border-color:var(--red-border); }
        .badge-med      { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-low      { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .badge-pending  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-complete { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .subj-pill { display:inline-flex; align-items:center; padding:2px 9px; border-radius:20px; font-size:11.5px; font-weight:500; background:rgba(74,111,165,0.10); color:#3a5a8c; border:1px solid #b8cde8; }

        /* Task table */
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }
        .card-header { display:flex; align-items:center; gap:10px; padding:16px 20px 14px; border-bottom:1px solid var(--border); }
        .card-header-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .card-header-title { font-size:15px; font-weight:600; flex:1; }
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
        .task-name { font-size:13.5px; font-weight:600; color:var(--text-dark); }
        .task-desc { font-size:12px; color:var(--text-muted); margin-top:2px; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
        .due-main { font-size:13px; font-weight:500; }
        .due-urgency { font-size:11px; font-weight:500; margin-top:1px; }
        .due-red { color:var(--red); } .due-orange { color:var(--orange); } .due-green { color:var(--green); }
        .btn-view { display:inline-flex; align-items:center; gap:4px; padding:5px 12px; border-radius:7px; background:var(--topbar); color:#fff; font-size:12px; font-weight:500; text-decoration:none; transition:background 0.15s; }
        .btn-view:hover { background:var(--hero-dark); }
        .btn-view i { font-size:14px; }
        .no-results { padding:36px 20px; text-align:center; color:var(--text-muted); font-size:13.5px; }

        /* Bottom row */
        .bottom-row { display:grid; grid-template-columns:1fr 1fr; gap:20px; }
        .class-row { display:flex; align-items:center; gap:10px; padding:9px 18px; transition:background 0.12s; text-decoration:none; color:var(--text-dark); }
        .class-row:hover { background:var(--bg); }
        .class-dot { width:9px; height:9px; border-radius:50%; flex-shrink:0; }
        .class-name-label { flex:1; font-size:13.5px; font-weight:500; }
        .class-pending-badge { font-size:11.5px; font-weight:600; color:var(--orange); background:var(--orange-bg); border:1px solid var(--orange-border); padding:1px 8px; border-radius:20px; }
        .class-done-label { font-size:11.5px; color:var(--text-muted); }
        .progress-list { padding:6px 18px 16px; display:flex; flex-direction:column; gap:12px; }
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
    <form id="frmDashboard" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Main</div>
                <a class="nav-item active" href="StudentDashboard.aspx">
                    <i class="ti ti-layout-dashboard"></i>
                    <span class="nav-item-label">My Dashboard</span>
                </a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class="nav-item" href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
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
                    <span class="current">PACE</span>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current">My Dashboard</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">My Dashboard</div>
                <div class="hero-sub">Welcome back, <asp:Label ID="lblHeroName" runat="server" />. You have <asp:Label ID="lblPendingCount" runat="server" /> tasks pending.</div>
            </div>

            <div class="filter-bar">
                <div class="filter-chips">
                    <button type="button" class="chip active" data-filter="all"      onclick="setChip(this)">All Tasks</button>
                    <button type="button" class="chip"        data-filter="pending"  onclick="setChip(this)">Pending</button>
                    <button type="button" class="chip"        data-filter="complete" onclick="setChip(this)">Completed</button>
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
                        <option value="subject">Sort: Subject</option>
                        <option value="status">Sort: Status</option>
                    </select>
                    <span class="filter-count" id="filterCount"></span>
                </div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlUrgent" runat="server" Visible="false">
                    <div>
                        <div class="section-label">Needs attention soon</div>
                        <div class="urgent-grid">
                            <asp:Repeater ID="rptUrgent" runat="server">
                                <ItemTemplate>
                                    <div class="urgent-card">
                                        <div class="urgent-inner <%# Convert.ToInt32(Eval("PriorityLevel")) == 3 ? "" : "orange" %>">
                                            <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px;">
                                                <div class="urgent-title"><%# Eval("Title") %></div>
                                                <%# GetPriorityBadge(Eval("PriorityLevel")) %>
                                            </div>
                                            <div class="urgent-meta">
                                                <span><i class="ti ti-book"></i> <%# Eval("Subject") %></span>
                                                <span><i class="ti ti-calendar"></i> <%# GetUrgencyText(Eval("DueDate")) %></span>
                                            </div>
                                        </div>
                                        <div class="urgent-footer">
                                            <span class="urgent-label" style="color:<%# Convert.ToInt32(Eval("PriorityLevel")) == 3 ? "var(--red)" : "var(--orange)" %>">
                                                <i class="ti ti-alert-triangle"></i> <%# GetUrgencyText(Eval("DueDate")) %>
                                            </span>
                                            <a class="btn-view" href='TaskDetail.aspx?TaskID=<%# Eval("TaskID") %>'><i class="ti ti-eye"></i> View</a>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>
                </asp:Panel>

                <div>
                    <div class="section-label">All Tasks</div>
                    <div class="card table-card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">Homework Tasks</span>
                            <span style="font-size:13px;color:var(--text-muted);"><asp:Label ID="lblTaskCount" runat="server" /> tasks</span>
                        </div>

                        <asp:Repeater ID="rptTasks" runat="server">
                            <HeaderTemplate>
                                <table class="task-table">
                                    <thead>
                                        <tr><th>Task</th><th>Subject</th><th>Due Date</th><th>Priority</th><th>Status</th><th>Action</th></tr>
                                    </thead>
                                    <tbody id="taskTbody">
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr class="task-row"
                                    data-status='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "complete" : "pending" %>'
                                    data-priority='<%# Eval("PriorityLevel") %>'
                                    data-title='<%# Eval("Title").ToString().ToLower().Replace("'","") %>'
                                    data-subject='<%# Eval("Subject").ToString().ToLower().Replace("'","") %>'
                                    data-due='<%# Convert.ToDateTime(Eval("DueDate")).ToString("yyyy-MM-dd") %>'
                                    data-overdue='<%# Convert.ToDateTime(Eval("DueDate")).Date < DateTime.Today ? "1" : "0" %>'>
                                    <td>
                                        <div class="task-name"><%# Eval("Title") %></div>
                                        <div class="task-desc"><%# Eval("Description") %></div>
                                    </td>
                                    <td><span class="subj-pill"><%# Eval("Subject") %></span></td>
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

                        <div id="noResults" class="no-results" style="display:none;">No tasks match your current filter or search.</div>
                        <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                            <div class="no-results">No tasks assigned yet.</div>
                        </asp:Panel>
                    </div>
                </div>

                <div class="bottom-row">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-school" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">My Classes</span>
                        </div>
                        <asp:Repeater ID="rptBottomClasses" runat="server">
                            <ItemTemplate>
                                <a class="class-row" href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                                    <span class="class-dot" style="background:<%# Eval("DotColor") %>;"></span>
                                    <span class="class-name-label"><%# Eval("ClassName") %></span>
                                    <%# Convert.ToInt32(Eval("PendingCount")) > 0
                                        ? "<span class='class-pending-badge'>" + Eval("PendingCount") + " pending</span>"
                                        : "<span class='class-done-label'>All done</span>" %>
                                </a>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-chart-bar" style="color:#3a9e6e;font-size:17px;"></i></div>
                            <span class="card-header-title">Completion Progress</span>
                        </div>
                        <div class="progress-list">
                            <asp:Repeater ID="rptProgress" runat="server">
                                <ItemTemplate>
                                    <div>
                                        <div class="progress-label-row">
                                            <span class="progress-subj"><%# Eval("ClassName") %></span>
                                            <span class="progress-pct"><%# Eval("PctDisplay") %></span>
                                        </div>
                                        <div class="progress-track">
                                            <div class="progress-fill <%# Eval("PctClass") %>" style="width:<%# Eval("PctWidth") %>%"></div>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>
                </div>

            </div>
        </div>

    </form>

    <script>
        var activeFilter = 'all';

        function setChip(el) {
            document.querySelectorAll('.chip').forEach(function(c) { c.classList.remove('active'); });
            el.classList.add('active');
            activeFilter = el.dataset.filter;
            applyFilters();
        }

        function applyFilters() {
            var search  = document.getElementById('searchInput').value.toLowerCase();
            var sortBy  = document.getElementById('sortSelect').value;
            var tbody   = document.getElementById('taskTbody');
            if (!tbody) return;

            var rows = Array.from(document.querySelectorAll('.task-row'));
            var visibleCount = 0;

            rows.forEach(function(row) {
                var show = true;
                if (activeFilter === 'pending'  && row.dataset.status !== 'pending')  show = false;
                if (activeFilter === 'complete' && row.dataset.status !== 'complete') show = false;
                if (activeFilter === 'high'     && row.dataset.priority !== '3')      show = false;
                if (activeFilter === 'overdue'  && row.dataset.overdue !== '1')       show = false;
                if (search && !row.dataset.title.includes(search) && !row.dataset.subject.includes(search)) show = false;
                row.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });

            // Re-sort visible rows
            var visible = rows.filter(function(r) { return r.style.display !== 'none'; });
            visible.sort(function(a, b) {
                if (sortBy === 'due')      return a.dataset.due.localeCompare(b.dataset.due);
                if (sortBy === 'priority') return parseInt(b.dataset.priority) - parseInt(a.dataset.priority);
                if (sortBy === 'subject')  return a.dataset.subject.localeCompare(b.dataset.subject);
                if (sortBy === 'status')   return a.dataset.status.localeCompare(b.dataset.status);
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