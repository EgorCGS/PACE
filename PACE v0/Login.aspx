<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="PACE.Login" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>PACE - Sign In</title>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet" />
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        html, body {
            font-family: 'DM Sans', sans-serif;
            background: #ddeaf7;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #1a2d42;
        }

        .login-card {
            background: #ffffff;
            border: 1px solid #c5daf0;
            border-radius: 16px;
            padding: 48px 40px;
            width: 380px;
            box-shadow: 0 4px 24px rgba(74,111,165,0.12);
        }

        .pace-brand {
            font-family: 'Cormorant Garamond', Georgia, serif;
            font-weight: 300;
            font-size: 56px;
            letter-spacing: 0.35em;
            color: #4a6fa5;
            text-align: center;
            line-height: 1;
            margin-bottom: 6px;
        }

        .pace-subtitle {
            font-size: 11.5px;
            font-weight: 500;
            letter-spacing: 0.15em;
            text-transform: uppercase;
            color: #7a9fbe;
            text-align: center;
            margin-bottom: 40px;
        }

        .form-group { margin-bottom: 18px; }

        .form-label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: #1a2d42;
            margin-bottom: 7px;
            letter-spacing: 0.04em;
        }

        .field-input {
            width: 100%;
            padding: 10px 14px;
            border: 1.5px solid #c5daf0;
            border-radius: 8px;
            background: #f0f5fb;
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            color: #1a2d42;
            outline: none;
            transition: border-color 0.15s, box-shadow 0.15s, background 0.15s;
        }

        .field-input:focus {
            border-color: #5b7db8;
            background: #ffffff;
            box-shadow: 0 0 0 3px rgba(91,125,184,0.14);
        }

        .field-input::placeholder { color: #7a9fbe; }

        .field-input.error {
            border-color: #d95c5c;
            background: #fdf0f0;
        }

        .field-input.error:focus {
            border-color: #d95c5c;
            box-shadow: 0 0 0 3px rgba(217,92,92,0.13);
        }

        .field-error {
            display: block;
            font-size: 12px;
            color: #d95c5c;
            margin-top: 5px;
        }

        .login-error {
            background: #fdf0f0;
            border: 1px solid #f0b8b8;
            border-radius: 8px;
            padding: 10px 14px;
            margin-bottom: 20px;
            font-size: 13px;
            color: #d95c5c;
        }

        .login-btn {
            width: 100%;
            padding: 11px;
            background: #4a6fa5;
            color: #ffffff;
            border: none;
            border-radius: 8px;
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.15s;
            margin-top: 8px;
        }

        .login-btn:hover { background: #3a5a8c; }
    </style>
</head>
<body>
    <form id="frmLogin" runat="server">
        <div class="login-card">

            <h1 class="pace-brand">PACE</h1>
            <p class="pace-subtitle">Homework Manager</p>

            <asp:Panel ID="pnlLoginError" runat="server" Visible="false">
                <div class="login-error">Incorrect username or password. Please try again.</div>
            </asp:Panel>

            <div class="form-group">
                <label class="form-label">Username</label>
                <asp:TextBox ID="txtUsername" runat="server" CssClass="field-input" placeholder="Enter your username" MaxLength="50" />
                <asp:Label ID="lblUsernameError" runat="server" CssClass="field-error" Visible="false">Username is required.</asp:Label>
            </div>

            <div class="form-group">
                <label class="form-label">Password</label>
                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="field-input" placeholder="Enter your password" MaxLength="128" />
                <asp:Label ID="lblPasswordError" runat="server" CssClass="field-error" Visible="false">Password is required.</asp:Label>
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="Sign in" CssClass="login-btn" OnClick="btnLogin_Click" />

        </div>
    </form>
</body>
</html>