# =========================================================================
# Pro Textile Système 1 — application complète portée en C# (WinForms)
# À lancer avec :  powershell -ExecutionPolicy Bypass -File ProTextile.ps1
# SQLite intégré (winsqlite3.dll, fourni avec Windows 10+) — aucune installation requise.
# =========================================================================
$ErrorActionPreference = 'Stop'
$cs = @'
// ===== part01_core.cs =====
// ============================================================================
//  Pro Textile Syst\u00E8me 1 \u2013 Textile Management System (portage C# / WinForms)
//  G\u00E9n\u00E9r\u00E9 depuis mai.py (Python/Tkinter/SQLite) \u2013 conversion 1:1.
//  Ex\u00E9cutable directement dans PowerShell via Add-Type (pr\u00E9ambule .ps1).
// ============================================================================
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Ports;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace PTS
{
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Constantes \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
public static class C
{
    public const string APP = "Pro Textile Syst\u00E8me 1";
    public static readonly Font FONT = new Font("Segoe UI", 9f);
    public static Font FONTB = new Font("Segoe UI", 9f, FontStyle.Bold);
    public static Font FONTH = new Font("Segoe UI", 16f, FontStyle.Bold);
    public const string BG = "White";

    public static readonly Dictionary<string, string> NAMES = new Dictionary<string, string> {
        {"client", "Clients"}, {"fournisseur", "Fournisseurs"}, {"transporteur", "Transporteurs"},
        {"reference", "R\u00E9f\u00E9rences"}, {"coloris", "Coloris"}, {"marque", "Marques"}, {"unite", "Unit\u00E9s"}};
    public static readonly string[] SIZES = {"XS", "S", "M", "L", "XL", "XXL"};
    public static readonly Dictionary<string, double> COEF = new Dictionary<string, double> {
        {"XS", .92}, {"S", .96}, {"M", 1}, {"L", 1.05}, {"XL", 1.1}, {"XXL", 1.16}};
    public static readonly Dictionary<string, string[][]> SEED = new Dictionary<string, string[][]> {
        {"client", new[]{ new[]{"ORY","ORY INTERNATIONAL"} }},
        {"fournisseur", new[]{ new[]{"SIF","SIF"} }},
        {"transporteur", new[]{ new[]{"DHL","DHL EXPRESS"} }},
        {"reference", new[]{ new[]{"MALALLA","MALALLA"}, new[]{"T-730","T-730"},
            new[]{"BASIC 2411","BASIC 2411 BLUE LAKE"}, new[]{"667S","667S"}, new[]{"M-18992","M/18992"} }},
        {"coloris", new[]{ new[]{"BLANC","BLANC"}, new[]{"NOIR","NOIR"}, new[]{"NC","NC"},
            new[]{"AZULIN","AZULINA"}, new[]{"IVOIRE","IVOIRE"} }},
        {"marque", new[]{ new[]{"ORY","ORY"} }},
        {"unite", new[]{ new[]{"ML","M\u00C8TRE LIN\u00C9AIRE"}, new[]{"M","M\u00C8TRE"}, new[]{"U","UNIT\u00C9"},
            new[]{"PR","PAIRE"}, new[]{"PC","PI\u00C8CES"}, new[]{"CO","C\u00D4NES"} }}};

    public const string SCHEMA = @"
CREATE TABLE IF NOT EXISTS tiers(kind TEXT, code TEXT, lib TEXT, PRIMARY KEY(kind, code));
CREATE TABLE IF NOT EXISTS rec(id TEXT PRIMARY KEY, date TEXT, tr TEXT, lb TEXT, ca REAL, cr REAL,
  ir INT, pd INT, ra INT, cm TEXT);
CREATE TABLE IF NOT EXISTS lig(rec TEXT, lig TEXT, dn TEXT, fo TEXT, rf TEXT, co TEXT, mq TEXT, nb INT,
  qt REAL, qu REAL, un TEXT, bl TEXT, fa TEXT, df TEXT, nl INT, lc INT, om INT, pf INT, PRIMARY KEY(rec, lig));
CREATE TABLE IF NOT EXISTS eti(id TEXT PRIMARY KEY, rec TEXT, lig TEXT, rf TEXT, co TEXT, fo TEXT, dn TEXT,
  un TEXT, an REAL, qt REAL, emp TEXT, lot TEXT, cd TEXT, pc TEXT, ob TEXT, st TEXT, ty TEXT, d TEXT, ts REAL);
CREATE TABLE IF NOT EXISTS lot(rec TEXT, lig TEXT, lot TEXT, chrono TEXT, v TEXT, l TEXT, PRIMARY KEY(rec, lig, lot));
CREATE TABLE IF NOT EXISTS nom(rf TEXT, co TEXT, c REAL, PRIMARY KEY(rf, co));
CREATE TABLE IF NOT EXISTS cmd(n TEXT PRIMARY KEY, pcs INT, st TEXT, d TEXT, tl TEXT);
CREATE TABLE IF NOT EXISTS cmdl(n TEXT, rf TEXT, co TEXT, q REAL, p REAL, PRIMARY KEY(n, rf, co));
CREATE TABLE IF NOT EXISTS hist(ts TEXT, msg TEXT);
CREATE TABLE IF NOT EXISTS cfg(k TEXT PRIMARY KEY, v TEXT);
";

    public static readonly string[][] TESTS_LABO = {
        new[]{"ASPECT", "CONTR\u00D4LE ASPECT TOUT KIND"}, new[]{"MOULA", "VALIDATION MOULAGE"},
        new[]{"OKLML", "VALIDATION LA MAISON LEJABY"}, new[]{"PLATE", "PLATITUDE"},
        new[]{"VISLAI", "VISITAGE TISSU"}, new[]{"SOLID", "SOLIDIT\u00C9 TEINTURE"},
        new[]{"GRAMM", "GRAMMAGE"}, new[]{"RETRR", "RETRAIT LAVAGE"}};

    public const string HTML_HEAD = "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\"><title>Impression</title><style>\n" +
        "body{font:13px sans-serif}.lb{border:1px solid #000;padding:3mm;width:90mm;display:inline-block;margin:2mm;\n" +
        "vertical-align:top;page-break-inside:avoid}.lb b{font:700 16px monospace;display:block}\n" +
        "svg{display:block;margin-top:2mm;height:12mm;max-width:100%}table{border-collapse:collapse;width:100%}\n" +
        "td,th{border:1px solid #000;padding:3px;text-align:left}</style></head><body>";

    public const string LOGO_PNG_B64 = "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";
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 JSON minimal (parse + dump) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
public static class Json
{
    public static object Parse(string s)
    {
        int i = 0;
        object v = Val(s, ref i);
        return v;
    }
    static void Ws(string s, ref int i) { while (i < s.Length && char.IsWhiteSpace(s[i])) i++; }
    static object Val(string s, ref int i)
    {
        Ws(s, ref i);
        if (i >= s.Length) return null;
        char c = s[i];
        if (c == '{')
        {
            var d = new Dictionary<string, object>(); i++;
            Ws(s, ref i);
            if (i < s.Length && s[i] == '}') { i++; return d; }
            while (true)
            {
                Ws(s, ref i);
                string k = (string)Val(s, ref i);
                Ws(s, ref i); i++; // ':'
                object v = Val(s, ref i);
                d[k] = v; Ws(s, ref i);
                if (i < s.Length && s[i] == ',') { i++; continue; }
                if (i < s.Length && s[i] == '}') { i++; break; }
                break;
            }
            return d;
        }
        if (c == '[')
        {
            var a = new List<object>(); i++;
            Ws(s, ref i);
            if (i < s.Length && s[i] == ']') { i++; return a; }
            while (true)
            {
                object v = Val(s, ref i);
                a.Add(v); Ws(s, ref i);
                if (i < s.Length && s[i] == ',') { i++; continue; }
                if (i < s.Length && s[i] == ']') { i++; break; }
                break;
            }
            return a;
        }
        if (c == '"')
        {
            var sb = new StringBuilder(); i++;
            while (i < s.Length && s[i] != '"')
            {
                if (s[i] == '\\' && i + 1 < s.Length)
                {
                    i++;
                    char e = s[i];
                    if (e == 'n') sb.Append('\n');
                    else if (e == 't') sb.Append('\t');
                    else if (e == 'r') sb.Append('\r');
                    else if (e == 'u' && i + 4 < s.Length)
                    { sb.Append((char)Convert.ToInt32(s.Substring(i + 1, 4), 16)); i += 4; }
                    else sb.Append(e);
                }
                else sb.Append(s[i]);
                i++;
            }
            i++; return sb.ToString();
        }
        if (i + 4 <= s.Length && s.Substring(i, 4) == "true") { i += 4; return true; }
        if (i + 5 <= s.Length && s.Substring(i, 5) == "false") { i += 5; return false; }
        if (i + 4 <= s.Length && s.Substring(i, 4) == "null") { i += 4; return null; }
        int st = i;
        while (i < s.Length && "-+.eE0123456789".IndexOf(s[i]) >= 0) i++;
        double d2;
        if (double.TryParse(s.Substring(st, i - st), NumberStyles.Float, CultureInfo.InvariantCulture, out d2)) return d2;
        i++; return null;
    }
    public static string Dump(object o) { var sb = new StringBuilder(); D(o, sb, false); return sb.ToString(); }
    public static string DumpU(object o) { var sb = new StringBuilder(); D(o, sb, true); return sb.ToString(); }
    static void D(object o, StringBuilder sb, bool uni)
    {
        if (o == null) { sb.Append("null"); return; }
        if (o is string) { Str((string)o, sb, uni); return; }
        if (o is bool) { sb.Append((bool)o ? "true" : "false"); return; }
        if (o is double) { sb.Append(((double)o).ToString("R", CultureInfo.InvariantCulture)); return; }
        if (o is int || o is long) { sb.Append(Convert.ToString(o, CultureInfo.InvariantCulture)); return; }
        if (o is IList<object>)
        {
            sb.Append('[');
            foreach (object x in (IList<object>)o) { D(x, sb, uni); sb.Append(','); }
            if (sb[sb.Length - 1] == ',') sb.Length--;
            sb.Append(']'); return;
        }
        if (o is IDictionary<string, object>)
        {
            sb.Append('{');
            foreach (KeyValuePair<string, object> kv in (IDictionary<string, object>)o)
            { Str(kv.Key, sb, uni); sb.Append(':'); D(kv.Value, sb, uni); sb.Append(','); }
            if (sb[sb.Length - 1] == ',') sb.Length--;
            sb.Append('}'); return;
        }
        Str(Convert.ToString(o, CultureInfo.InvariantCulture), sb, uni);
    }
    static void Str(string s, StringBuilder sb, bool uni)
    {
        sb.Append('"');
        foreach (char ch in s)
        {
            if (ch == '"') sb.Append("\\\"");
            else if (ch == '\\') sb.Append("\\\\");
            else if (ch == '\n') sb.Append("\\n");
            else if (ch == '\r') sb.Append("\\r");
            else if (ch == '\t') sb.Append("\\t");
            else if ((int)ch < 32) sb.Append("\\u" + ((int)ch).ToString("x4"));
            else if (uni && (int)ch > 127) sb.Append("\\u" + ((int)ch).ToString("x4"));
            else sb.Append(ch);
        }
        sb.Append('"');
    }
    // acc\u00E8s pratique
    public static string S(object o, string k) { var d = o as IDictionary<string, object>; return d != null && d.ContainsKey(k) && d[k] != null ? Convert.ToString(d[k], CultureInfo.InvariantCulture) : null; }
    public static double N(object o, string k) { var d = o as IDictionary<string, object>; if (d == null || !d.ContainsKey(k) || d[k] == null) return 0; if (d[k] is double) return (double)d[k]; double r; double.TryParse(Convert.ToString(d[k], CultureInfo.InvariantCulture), NumberStyles.Any, CultureInfo.InvariantCulture, out r); return r; }
    public static long I(object o, string k) { return (long)N(o, k); }
    public static IList<object> L(object o, string k) { var d = o as IDictionary<string, object>; if (d == null || !d.ContainsKey(k)) return new List<object>(); var l = d[k] as IList<object>; return l != null ? l : new List<object>(); }
    public static IDictionary<string, object> Dd(object o, string k) { var d = o as IDictionary<string, object>; if (d == null || !d.ContainsKey(k)) return new Dictionary<string, object>(); var m = d[k] as IDictionary<string, object>; return m != null ? m : new Dictionary<string, object>(); }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 SQLite via winsqlite3.dll (int\u00E9gr\u00E9 Windows 10+) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
public class Row
{
    string[] cols; object[] vals;
    public Row(string[] c, object[] v) { cols = c; vals = v; }
    public object this[string col]
    {
        get
        {
            for (int i = 0; i < cols.Length; i++) if (cols[i].Equals(col, StringComparison.OrdinalIgnoreCase)) return vals[i];
            return null;
        }
    }
    public string S(string col) { object o = this[col]; return o == null ? null : Convert.ToString(o, CultureInfo.InvariantCulture); }
    public double D(string col) { object o = this[col]; if (o == null) return 0; if (o is double) return (double)o; if (o is long) return (double)(long)o; double r; double.TryParse(Convert.ToString(o, CultureInfo.InvariantCulture), NumberStyles.Any, CultureInfo.InvariantCulture, out r); return r; }
    public long L(string col) { object o = this[col]; if (o == null) return 0; if (o is long) return (long)o; if (o is double) return (long)(double)o; long r; long.TryParse(Convert.ToString(o, CultureInfo.InvariantCulture), out r); return r; }
    public bool B(string col, string v) { string s = S(col); return s != null && Array.IndexOf(v.Split('|'), s) >= 0; }
}

public class SqliteErr : Exception { public SqliteErr(string m) : base(m) { } }

public class Db
{
    IntPtr h = IntPtr.Zero;
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_open_v2", CallingConvention = CallingConvention.Cdecl)]
    static extern int open(byte[] fn, out IntPtr db, int flags, IntPtr vfs);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_close_v2", CallingConvention = CallingConvention.Cdecl)]
    static extern int close(IntPtr db);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_prepare_v2", CallingConvention = CallingConvention.Cdecl)]
    static extern int prepare(IntPtr db, byte[] sql, int n, out IntPtr stmt, out IntPtr tail);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_step", CallingConvention = CallingConvention.Cdecl)]
    static extern int step(IntPtr stmt);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_finalize", CallingConvention = CallingConvention.Cdecl)]
    static extern int finalize(IntPtr stmt);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_bind_text", CallingConvention = CallingConvention.Cdecl)]
    static extern int bind_text(IntPtr stmt, int i, byte[] v, int n, IntPtr f);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_bind_double", CallingConvention = CallingConvention.Cdecl)]
    static extern int bind_double(IntPtr stmt, int i, double v);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_bind_int64", CallingConvention = CallingConvention.Cdecl)]
    static extern int bind_int64(IntPtr stmt, int i, long v);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_bind_null", CallingConvention = CallingConvention.Cdecl)]
    static extern int bind_null(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_count", CallingConvention = CallingConvention.Cdecl)]
    static extern int col_count(IntPtr stmt);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_name", CallingConvention = CallingConvention.Cdecl)]
    static extern IntPtr col_name(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_type", CallingConvention = CallingConvention.Cdecl)]
    static extern int col_type(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_text", CallingConvention = CallingConvention.Cdecl)]
    static extern IntPtr col_text(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_double", CallingConvention = CallingConvention.Cdecl)]
    static extern double col_double(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_column_int64", CallingConvention = CallingConvention.Cdecl)]
    static extern long col_int(IntPtr stmt, int i);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_exec", CallingConvention = CallingConvention.Cdecl)]
    static extern int exec(IntPtr db, byte[] sql, IntPtr cb, IntPtr arg, out IntPtr err);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_errmsg", CallingConvention = CallingConvention.Cdecl)]
    static extern IntPtr errmsg(IntPtr db);
    [DllImport("winsqlite3.dll", EntryPoint = "sqlite3_busy_timeout", CallingConvention = CallingConvention.Cdecl)]
    static extern int busy(IntPtr db, int ms);

    static byte[] B(string s) { return Encoding.UTF8.GetBytes(s + "\0"); }
    static string S(IntPtr p) { return Marshal.PtrToStringUTF8(p); }

    public Db(string path)
    {
        // SQLITE_OPEN_READWRITE(2) | SQLITE_OPEN_CREATE(4)
        int rc = open(B(path), out h, 2 | 4, IntPtr.Zero);
        if (rc != 0) throw new SqliteErr("Impossible d'ouvrir la base " + path + " (code " + rc + ")");
        busy(h, 3000);
    }
    string Err() { return S(errmsg(h)); }

    public List<Row> Q(string sql, object[] a)
    {
        IntPtr st;
        IntPtr tail;
        int rc = prepare(h, B(sql), B(sql).Length - 1, out st, out tail);
        if (rc != 0) throw new SqliteErr(Err() + " \u2014 " + sql);
        try
        {
            Bind(st, a);
            var rows = new List<Row>();
            while (true)
            {
                rc = step(st);
                if (rc == 100) // SQLITE_ROW
                {
                    int n = col_count(st);
                    var cols = new string[n]; var vals = new object[n];
                    for (int i = 0; i < n; i++)
                    {
                        cols[i] = S(col_name(st, i));
                        int t = col_type(st, i);
                        if (t == 1) vals[i] = col_int(st, i);          // INTEGER
                        else if (t == 2) vals[i] = col_double(st, i);  // FLOAT
                        else if (t == 3) vals[i] = S(col_text(st, i)); // TEXT
                        else if (t == 4) vals[i] = new byte[0];        // BLOB
                        else vals[i] = null;
                    }
                    rows.Add(new Row(cols, vals));
                }
                else if (rc == 101) break; // SQLITE_DONE
                else throw new SqliteErr(Err());
            }
            return rows;
        }
        finally { finalize(st); }
    }

    void Bind(IntPtr st, object[] a)
    {
        for (int i = 0; i < a.Length; i++)
        {
            object v = a[i]; int p = i + 1;
            if (v == null) bind_null(st, p);
            else if (v is double) bind_double(st, p, (double)v);
            else if (v is int) bind_int64(st, p, (int)v);
            else if (v is long) bind_int64(st, p, (long)v);
            else if (v is bool) bind_int64(st, p, (bool)v ? 1 : 0);
            else bind_text(st, p, B(Convert.ToString(v, CultureInfo.InvariantCulture)), -1, new IntPtr(-1));
        }
    }

    public int X(string sql, object[] a)
    {
        IntPtr st, tail;
        int rc = prepare(h, B(sql), B(sql).Length - 1, out st, out tail);
        if (rc != 0) throw new SqliteErr(Err() + " \u2014 " + sql);
        try { Bind(st, a); rc = step(st); if (rc != 101 && rc != 100) throw new SqliteErr(Err()); }
        finally { finalize(st); }
        return rc;
    }
    public void Script(string sql)
    {
        IntPtr err;
        int rc = exec(h, B(sql), IntPtr.Zero, IntPtr.Zero, out err);
        if (rc != 0) throw new SqliteErr(S(err));
    }
    public void Close() { if (h != IntPtr.Zero) { close(h); h = IntPtr.Zero; } }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Outils (port des fonctions module) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
public static class U
{
    public static string BaseDir()
    {
        return AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\') + "\\";
    }
    public static double Num(object s)
    {
        if (s == null) return 0;
        if (s is double) return (double)s;
        if (s is long) return (double)(long)s;
        if (s is int) return (int)s;
        double r;
        double.TryParse(Convert.ToString(s, CultureInfo.InvariantCulture).Replace(",", ".").Trim(),
                        NumberStyles.Any, CultureInfo.InvariantCulture, out r);
        return r;
    }
    public static string F3(double n) { return n.ToString("0.000", CultureInfo.InvariantCulture).Replace(".", ","); }
    public static string TodayFr() { return DateTime.Today.ToString("dd/MM/yyyy"); }

    static readonly Dictionary<string, string> C39 = new Dictionary<string, string> {
        {"0","nnnwwnwnn"},{"1","wnnwnnnnw"},{"2","nnwwnnnnw"},{"3","wnwwnnnnn"},{"4","nnnwwnnnw"},
        {"5","wnnwwnnnn"},{"6","nnwwwnnnn"},{"7","nnnwnnwnw"},{"8","wnnwnnwnn"},{"9","nnwwnnwnn"},{"*","nwnnwnwnn"}};

    public static string BarcodeSvg(string s)
    {
        int x = 0; var r = new StringBuilder();
        string code = "*" + s + "*";
        foreach (char ch in code)
        {
            string p; if (!C39.TryGetValue(Convert.ToString(ch), out p)) continue;
            for (int i = 0; i < p.Length; i++)
            {
                int w = p[i] == 'w' ? 3 : 1;
                if (i % 2 == 0) r.Append("<rect x=\"" + x + "\" width=\"" + w + "\" height=\"40\"/>");
                x += w;
            }
            x += 1;
        }
        return "<svg viewBox=\"0 0 " + x + " 40\" width=\"" + Math.Round(x * .9) + "\" height=\"40\" fill=\"#000\">" + r + "</svg>";
    }

    public static string Zpl(Row e)
    {
        return "^XA^CI28^PW800^LL400" +
            "^FO30,25^A0N,30,30^FD" + T(e.S("rf")) + " " + T(e.S("co")) + "^FS" +
            "^FO30,65^A0N,24,24^FD" + T(e.S("fo")) + "  " + F3(e.D("qt")) + " " + T(e.S("un")) + "^FS" +
            "^FO30,100^A0N,24,24^FDEmpl. " + T(e.S("emp")) + "  Lot " + T(e.S("lot")) + "^FS" +
            "^FO30,140^BY2,3,90^B3N,N,90,N,N^FD" + e.S("id") + "^FS" +
            "^FO30,250^A0N,30,30^FD" + e.S("id") + "^FS^XZ";
    }
    static string T(string s) { return (s ?? "").Replace("^", "").Replace("~", ""); }

    public static string ZplTest()
    {
        return "^XA^CI28^PW448^LL240" +
            "^FO30,30^A0N,36,36^FDTEST PRO TEXTILE SYSTEME^FS" +
            "^FO30,90^A0N,28,28^FDEtiquette de test^FS^XZ";
    }

    public static string ZplPiplette(Row e, Store S)
    {
        string d = DateTime.Today.ToString("dd/MM/yy");
        return "^XA^CI28^PW800^LL640" +
            "^FO30,20^A0N,44,44^FDPRO TEXTIL^FS" +
            "^FO560,20^A0N,30,30^FD" + T(e.S("fo")) + "^FS" +
            "^FO560,60^A0N,26,26^FD" + d + "^FS" +
            "^FO30,80^BY3,3,120^B3N,N,120,N,N^FD" + e.S("id") + "^FS" +
            "^FO30,220^A0N,50,50^FD" + T(e.S("rf")) + "^FS" +
            "^FO30,285^A0N,32,32^FD" + T(string.IsNullOrEmpty(S.Lib("reference", e.S("rf"))) ? e.S("rf") : S.Lib("reference", e.S("rf"))) + "^FS" +
            "^FO30,330^A0N,30,30^FDColoris : " + T(e.S("co")) + "  " + T(S.Lib("coloris", e.S("co")) ?? "") + "^FS" +
            "^FO30,375^A0N,30,30^FDQt\u00E9 : " + F3(e.D("qt")) + " " + T(e.S("un")) + "   TFT   Fournisseur^FS" +
            "^FO30,420^A0N,30,30^FDEmplacement : " + T(e.S("emp")) + "   Code : " + e.S("id") + "^FS" +
            "^FO30,465^A0N,30,30^FDLot : " + T(e.S("lot")) + "   Tiers : " + T(e.S("fo")) + "^FS^XZ";
    }

    public static void SendNet(byte[] data, string ip, object port)
    {
        if (string.IsNullOrEmpty(ip))
            throw new ValueError("Adresse IP de la Zebra non renseign\u00E9e (menu Imprimante Zebra).");
        int p = 9100; int.TryParse(Convert.ToString(port), out p); if (p <= 0) p = 9100;
        using (TcpClient c = new TcpClient())
        {
            IAsyncResult ar = c.BeginConnect(ip, p, null, null);
            if (!ar.AsyncWaitHandle.WaitOne(5000)) throw new ValueError("D\u00E9lai d\u00E9pass\u00E9 : imprimante " + ip + ":" + p + " injoignable.");
            c.EndConnect(ar);
            using (NetworkStream s = c.GetStream()) { s.Write(data, 0, data.Length); s.Flush(); }
        }
    }

    public static void SendSerial(byte[] data, string com, object baud, object bits, object stop, object par,
                                  object dtr, double tmo, object buf)
    {
        string pr = "N";
        string pk = (par ?? "").ToString().Trim().ToLowerInvariant();
        if (pk == "paire" || pk == "even") pr = "E";
        else if (pk == "impaire" || pk == "odd") pr = "O";
        string port = (com ?? "").Trim();
        if (port != "" && CharIsDigit(port)) port = "COM" + port;
        try
        {
            int bd = 9600, bs = 8, sb = 1;
            int.TryParse(Convert.ToString(baud), out bd);
            int.TryParse(Convert.ToString(bits), out bs);
            int.TryParse(Convert.ToString(stop), out sb);
            bool dsrdtr = Num(dtr) != 0;
            using (SerialPort s = new SerialPort(port, bd, (Parity)Enum.Parse(typeof(Parity), pr), bs, (StopBits)(sb == 2 ? 2 : 1)))
            {
                s.ReadTimeout = (int)Math.Max(1, tmo * 1000);
                s.WriteTimeout = (int)Math.Max(tmo * 1000, 3000);
                s.DtrEnable = dsrdtr; s.RtsEnable = false;
                s.Open();
                int n = Math.Max(1, (int)Num(buf));
                for (int i = 0; i < data.Length; i += n)
                {
                    int len = Math.Min(n, data.Length - i);
                    byte[] chunk = new byte[len]; Array.Copy(data, i, chunk, 0, len);
                    s.Write(chunk, 0, len);
                    Thread.Sleep(100);
                }
            }
        }
        catch (Exception ex)
        {
            throw new ValueError("Port " + com + " inaccessible : " + ex.Message +
                "\nV\u00E9rifiez le port COM, le c\u00E2ble et que l'imprimante est allum\u00E9e.");
        }
    }
    static bool CharIsDigit(string s) { return s.Length > 0 && "0123456789".IndexOf(s[0]) >= 0; }

    public static void OpenHtml(string body, string name)
    {
        string p = Path.Combine(BaseDir(), name);
        File.WriteAllText(p, C.HTML_HEAD + body + "<script>window.onload=()=>window.print()</script></body></html>", new UTF8Encoding(false));
        try { System.Diagnostics.Process.Start(p); }
        catch { }
    }
    public static void OpenHtml(string body) { OpenHtml(body, "impression.html"); }

    public static string Esc(string s)
    {
        return (s ?? "").Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;");
    }

    public static string LabelsHtml(Store S, List<Row> rows)
    {
        var sb = new StringBuilder();
        foreach (Row e in rows)
        {
            sb.Append("<div class=\"lb\"><div>" + Esc(e.S("rf")) + " \u00B7 " + Esc(e.S("co")) + "</div><div>" + Esc(S.Lib("reference", e.S("rf"))) + "</div>" +
                "<div>" + Esc(e.S("fo")) + " \u00B7 " + F3(e.D("qt")) + " " + Esc(e.S("un")) + "</div><div>Empl. " + Esc(e.S("emp")) + " \u00B7Lot " + Esc(e.S("lot")) + "</div>" +
                BarcodeSvg(e.S("id")) + "<b>" + e.S("id") + "</b></div>");
        }
        return sb.ToString();
    }

    public static string SlipHtml(Row r, List<Row> lines)
    {
        var d = new Dictionary<string, object>();
        if (r != null) foreach (string k in new[] { "id", "date", "tr", "lb", "ca", "cr", "cm" }) d[k] = r[k];
        return SlipHtml((IDictionary<string, object>)d, lines);
    }

    public static string SlipHtml(IDictionary<string, object> r, List<Row> lines)
    {
        var tr = new StringBuilder();
        foreach (Row l in lines)
        {
            tr.Append("<tr><td>" + l.S("lig") + "</td><td>" + Esc(l.S("rf")) + "</td><td>" + Esc(l.S("co")) + "</td><td>" + Esc(l.S("fo")) + "</td>" +
                "<td>" + l.L("nb") + "</td><td>" + F3(l.D("qt")) + " " + Esc(l.S("un")) + "</td></tr>");
        }
        return "<h3>Bordereau de r\u00E9ception " + Esc(Json.S(r, "id")) + "</h3><p>Date " + Esc(Json.S(r, "date")) + " \u00B7 Transporteur " + Esc(Json.S(r, "tr")) +
            " \u00B7 " + Esc(Json.S(r, "lb")) + "<br>Colis annonc\u00E9s " + Esc(Json.S(r, "ca")) + " \u00B7 re\u00E7us " + Esc(Json.S(r, "cr")) + "<br>" + Esc(Json.S(r, "cm")) + "</p>" +
            "<table><tr><th>Lig.</th><th>R\u00E9f\u00E9rence</th><th>Coloris</th><th>Fournisseur</th><th>\u00C9tiq.</th>" +
            "<th>Qt\u00E9 / \u00E9tiq.</th></tr>" + tr + "</table>";
    }

    public static string ExportCsv(Store S, string rec)
    {
        string d = Path.Combine(BaseDir(), "exports");
        if (!Directory.Exists(d)) Directory.CreateDirectory(d);
        string p = Path.Combine(d, "reception-" + rec + ".csv");
        var sb = new StringBuilder();
        sb.AppendLine("Lig;Donneur;Fournisseur;R\u00E9f\u00E9rence;Coloris;Marque;\u00C9tiquettes;Qt\u00E9;Unit\u00E9");
        foreach (Row l in S.Lines(rec))
            sb.AppendLine(string.Join(";", new[] { l.S("lig"), l.S("dn"), l.S("fo"), l.S("rf"), l.S("co"), l.S("mq"),
                Convert.ToString(l.L("nb")), F3(l.D("qt")), l.S("un") }));
        File.WriteAllText(p, "\ufeff" + sb.ToString(), new UTF8Encoding(false));
        return p;
    }

    public static void Warn(Form w, string msg) { MessageBox.Show(w, msg, C.APP, MessageBoxButtons.OK, MessageBoxIcon.Warning); }
    public static void Info(Form w, string msg) { MessageBox.Show(w, msg, C.APP, MessageBoxButtons.OK, MessageBoxIcon.Information); }
    public static bool Ask(Form w, string msg) { return MessageBox.Show(w, msg, C.APP, MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes; }
}

public class ValueError : Exception { public ValueError(string m) : base(m) { } }
public class RuntimeError : Exception { public RuntimeError(string m) : base(m) { } }
}

// ===== part02_store.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Store (couche donn\u00E9es, port de la classe Store) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

public class Sz { public string T; public double C; public Sz(string t, double c) { T = t; C = c; } }
public class NeedResult { public double Pcs; public List<Row> Rows = new List<Row>(); }

public class Store
{
    Db db;
    public string Path;

    public Store(string path)
    {
        Path = string.IsNullOrEmpty(path) ? System.IO.Path.Combine(U.BaseDir(), "protextile.db") : path;
        db = new Db(Path);
        db.Script(C.SCHEMA);
        if (Q("SELECT 1 FROM tiers LIMIT 1").Count == 0)
        {
            foreach (KeyValuePair<string, string[][]> kv in C.SEED)
                foreach (string[] cl in kv.Value)
                    X("INSERT INTO tiers VALUES(?,?,?)", kv.Key, cl[0], cl[1]);
        }
        if (Q("SELECT 1 FROM nom LIMIT 1").Count == 0)
        {
            X("INSERT INTO nom VALUES(?,?,?)", "MALALLA", "BLANC", .45);
            X("INSERT INTO nom VALUES(?,?,?)", "T-730", "NOIR", .1);
        }
    }

    public List<Row> Q(string sql) { return db.Q(sql, new object[0]); }
    public List<Row> Q(string sql, params object[] a) { return db.Q(sql, a); }
    public void X(string sql, params object[] a) { db.X(sql, a); }
    public void Log(string msg)
    {
        X("INSERT INTO hist VALUES(?,?)", DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss"), msg);
    }

    public string Cfg(string k)
    {
        List<Row> r = Q("SELECT v FROM cfg WHERE k=?", k);
        return r.Count > 0 ? r[0].S("v") : "";
    }
    public string Cfg(string k, string d)
    {
        List<Row> r = Q("SELECT v FROM cfg WHERE k=?", k);
        return r.Count > 0 ? r[0].S("v") : d;
    }
    public void SetCfg(string k, object v)
    {
        X("INSERT OR REPLACE INTO cfg VALUES(?,?)", k, Convert.ToString(v, CultureInfo.InvariantCulture));
    }

    // tailles dynamiques
    public List<Sz> Sizes()
    {
        List<object> d = Json.Parse(Cfg("sizes") ?? "null") as List<object>;
        if (d == null || d.Count == 0)
        {
            var L = new List<Sz>();
            foreach (string t in C.SIZES) L.Add(new Sz(t, C.COEF[t]));
            return L;
        }
        var outp = new List<Sz>();
        foreach (object o in d)
        {
            var a = o as List<object>;
            if (a != null && a.Count >= 2)
                outp.Add(new Sz(Convert.ToString(a[0], CultureInfo.InvariantCulture), U.Num(a[1])));
        }
        return outp;
    }

    public void AddSize(string name, object coef)
    {
        name = (name ?? "").Trim().ToUpperInvariant();
        if (name == "") throw new ValueError("Indiquez le nom de la taille (ex : XXXL).");
        List<Sz> L = Sizes();
        foreach (Sz s in L) if (s.T == name) throw new ValueError("Cette taille existe d\u00E9j\u00E0.");
        double c = U.Num(coef); if (c == 0) c = 1.0;
        var arr = new List<object>();
        foreach (Sz s in L)
        {
            var p = new List<object>(); p.Add(s.T); p.Add(s.C); arr.Add(p);
        }
        var np = new List<object>(); np.Add(name); np.Add(c); arr.Add(np);
        SetCfg("sizes", Json.Dump(arr));
        Log("Taille " + name + " ajout\u00E9e (coefficient " + c.ToString("0.###", CultureInfo.InvariantCulture) + ")");
    }

    public void DelSize(string name)
    {
        var arr = new List<object>();
        foreach (Sz s in Sizes())
            if (s.T != name) { var p = new List<object>(); p.Add(s.T); p.Add(s.C); arr.Add(p); }
        SetCfg("sizes", Json.Dump(arr));
        Log("Taille " + name + " retir\u00E9e");
    }

    // tiers
    public List<Row> Tiers(string k) { return Q("SELECT code, lib FROM tiers WHERE kind=? ORDER BY code", k); }
    public string Lib(string k, string c)
    {
        List<Row> r = Q("SELECT lib FROM tiers WHERE kind=? AND code=?", k, (c ?? "").Trim().ToUpperInvariant());
        return r.Count > 0 ? r[0].S("lib") : "";
    }
    public void AddTiers(string k, string c, string l)
    {
        c = (c ?? "").Trim().ToUpperInvariant(); l = (l ?? "").Trim().ToUpperInvariant();
        if (c == "") throw new ValueError("Le code est requis.");
        X("INSERT OR REPLACE INTO tiers VALUES(?,?,?)", k, c, string.IsNullOrEmpty(l) ? c : l);
        Log("Tiers " + k + " " + c + " enregistr\u00E9");
    }
    public void DelTiers(string k, string c)
    {
        X("DELETE FROM tiers WHERE kind=? AND code=?", k, c);
        Log("Tiers " + k + " " + c + " supprim\u00E9");
    }

    // r\u00E9ceptions
    public string AddRec(string tr, string lb, object ca, object cr, string date, int ir, int pd, int ra, string cm)
    {
        tr = (tr ?? "").Trim().ToUpperInvariant(); lb = (lb ?? "").Trim();
        if (tr == "" || lb == "") throw new ValueError("Renseignez le transporteur et le libell\u00E9 (*).");
        string d = DateTime.Today.ToString("yyMMdd");
        List<Row> m0 = Q("SELECT MAX(CAST(substr(id,7) AS INTEGER)) m FROM rec WHERE id LIKE ?", d + "%");
        long m = m0.Count > 0 && m0[0]["m"] != null ? m0[0].L("m") : 0;
        string i = d + (m + 1).ToString("000");
        X("INSERT INTO rec VALUES(?,?,?,?,?,?,?,?,?,?)", i,
          string.IsNullOrEmpty(date) ? U.TodayFr() : date, tr, lb, U.Num(ca), U.Num(cr), ir, pd, ra, cm ?? "");
        Log("R\u00E9ception " + i + " enregistr\u00E9e");
        return i;
    }
    public Row Rec(string i)
    {
        List<Row> r = Q("SELECT * FROM rec WHERE id=?", i);
        return r.Count > 0 ? r[0] : null;
    }
    public void DelRec(string i)
    {
        if (Q("SELECT 1 FROM eti WHERE rec=? AND st IN ('LOGIQUE','SORTI')", i).Count > 0)
            throw new ValueError("Des \u00E9tiquettes sont d\u00E9j\u00E0 en stock : suppression impossible.");
        X("DELETE FROM eti WHERE rec=?", i);
        X("DELETE FROM lig WHERE rec=?", i);
        X("DELETE FROM lot WHERE rec=?", i);
        X("DELETE FROM rec WHERE id=?", i);
        Log("R\u00E9ception " + i + " supprim\u00E9e");
    }

    // lignes
    public List<Row> Lines(string rec) { return Q("SELECT * FROM lig WHERE rec=? ORDER BY lig", rec); }
    public Row Line(string rec, string lig)
    {
        List<Row> r = Q("SELECT * FROM lig WHERE rec=? AND lig=?", rec, lig);
        return r.Count > 0 ? r[0] : null;
    }

    public string SaveLine(string rec, IDictionary<string, string> f, string lig)
    {
        var l = new Dictionary<string, object>();
        foreach (string k in new[] { "dn", "fo", "rf", "co", "mq", "un" })
            l[k] = Get(f, k).Trim().ToUpperInvariant();
        l["nb"] = (long)U.Num(Get(f, "nb"));
        l["qt"] = U.Num(Get(f, "qt"));
        l["qu"] = U.Num(Get(f, "qu"));
        l["bl"] = Get(f, "bl").Trim();
        l["fa"] = Get(f, "fa").Trim();
        l["df"] = Get(f, "df").Trim();
        l["nl"] = (long)(U.Num(Get(f, "nl")) != 0 ? 1 : 0);
        l["lc"] = (long)(U.Num(Get(f, "lc")) != 0 ? 1 : 0);
        l["om"] = (long)(U.Num(Get(f, "om")) != 0 ? 1 : 0);
        l["pf"] = (long)(U.Num(Get(f, "pf")) != 0 ? 1 : 0);
        if (Str(l, "dn") == "" || Str(l, "fo") == "" || Str(l, "rf") == "" || Str(l, "co") == "")
            throw new ValueError("Donneur d\u2019ordre, fournisseur, r\u00E9f\u00E9rence et coloris sont requis.");
        if ((long)l["nb"] < 1 || (double)l["qt"] <= 0 || Str(l, "un") == "")
            throw new ValueError("Nombre d\u2019\u00E9tiquettes, Lg-Qt\u00E9 \u00E9tiquette et unit\u00E9 de r\u00E9ception sont requis (*).");
        foreach (string[] kf in new[] { new[] { "reference", "rf" }, new[] { "coloris", "co" },
                                        new[] { "marque", "mq" }, new[] { "unite", "un" } })
        {
            string fld = kf[1];
            if (Str(l, fld) != "" && Lib(kf[0], Str(l, fld)) == "")
                X("INSERT OR IGNORE INTO tiers VALUES(?,?,?)", kf[0], Str(l, fld), Str(l, fld));
        }
        l["rec"] = rec;
        if (lig == null)
        {
            List<Row> m0 = Q("SELECT MAX(CAST(lig AS INTEGER)) m FROM lig WHERE rec=?", rec);
            long m = m0.Count > 0 && m0[0]["m"] != null ? m0[0].L("m") : 0;
            l["lig"] = (m + 1).ToString("000");
            X("INSERT INTO lig(rec,lig,dn,fo,rf,co,mq,nb,qt,qu,un,bl,fa,df,nl,lc,om,pf) VALUES" +
              "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
              l["rec"], l["lig"], l["dn"], l["fo"], l["rf"], l["co"], l["mq"], l["nb"], l["qt"], l["qu"],
              l["un"], l["bl"], l["fa"], l["df"], l["nl"], l["lc"], l["om"], l["pf"]);
        }
        else
        {
            if (Q("SELECT 1 FROM eti WHERE rec=? AND lig=?", rec, lig).Count > 0)
                throw new ValueError("Cette ligne a d\u00E9j\u00E0 des \u00E9tiquettes : modification impossible.");
            l["lig"] = lig;
            X("UPDATE lig SET dn=?,fo=?,rf=?,co=?,mq=?,nb=?,qt=?,qu=?,un=?,bl=?,fa=?,df=?,nl=?,lc=?,om=?,pf=? " +
              "WHERE rec=? AND lig=?",
              l["dn"], l["fo"], l["rf"], l["co"], l["mq"], l["nb"], l["qt"], l["qu"], l["un"], l["bl"],
              l["fa"], l["df"], l["nl"], l["lc"], l["om"], l["pf"], rec, lig);
        }
        Log("Ligne " + Str(l, "lig") + " enregistr\u00E9e (r\u00E9ception " + rec + ")");
        return Str(l, "lig");
    }
    static string Get(IDictionary<string, string> f, string k) { string v; return f.TryGetValue(k, out v) ? (v ?? "") : ""; }
    static string Str(IDictionary<string, object> d, string k) { return Convert.ToString(d[k], CultureInfo.InvariantCulture); }

    public void DelLine(string rec, string lig)
    {
        if (Q("SELECT 1 FROM eti WHERE rec=? AND lig=? AND st IN ('LOGIQUE','SORTI')", rec, lig).Count > 0)
            throw new ValueError("Des \u00E9tiquettes sont d\u00E9j\u00E0 en stock : suppression impossible.");
        X("DELETE FROM eti WHERE rec=? AND lig=?", rec, lig);
        X("DELETE FROM lot WHERE rec=? AND lig=?", rec, lig);
        X("DELETE FROM lig WHERE rec=? AND lig=?", rec, lig);
    }

    // \u00E9tiquettes
    public List<Row> Labels(string rec, string lig)
    {
        if (lig == null) return new List<Row>();
        return Q("SELECT * FROM eti WHERE rec=? AND lig=? ORDER BY id", rec, lig);
    }
    public Row Label(string i)
    {
        List<Row> r = Q("SELECT * FROM eti WHERE id=?", i);
        return r.Count > 0 ? r[0] : null;
    }
    void NewLabel(Row L, int i)
    {
        X("INSERT INTO eti(id,rec,lig,rf,co,fo,dn,un,an,qt,emp,lot,cd,pc,ob,st,ty,d,ts) VALUES" +
          "(?,?,?,?,?,?,?,?,?,0,'','','','','','NRECEP','Mati\u00E8re',?,0)",
          L.S("rec") + L.S("lig") + i.ToString("000"), L.S("rec"), L.S("lig"), L.S("rf"), L.S("co"),
          L.S("fo"), L.S("dn"), L.S("un"), L.D("qt"), U.TodayFr());
    }
    public bool MakeLabels(string rec, string lig)
    {
        Row L = Line(rec, lig);
        if (Labels(rec, lig).Count > 0) return false;
        for (int i = 1; i <= L.L("nb"); i++) NewLabel(L, i);
        Log("Mise en stock r\u00E9ception " + rec + " ligne " + lig + " : " + L.L("nb") + " \u00E9tiquette(s)");
        return true;
    }
    public void EditLabel(string i, IDictionary<string, string> f)
    {
        Row e = Label(i);
        if (e.S("st") == "LOGIQUE" || e.S("st") == "SORTI")
            throw new ValueError("\u00C9tiquette d\u00E9j\u00E0 qualifi\u00E9e.");
        string emp = Get(f, "emp").Trim().ToUpperInvariant();
        double qt = U.Num(Get(f, "qt"));
        string st = emp != "" && qt > 0 ? "LABOET" : "NRECEP"; // r\u00E9ception \u2192 directement LABO ET
        X("UPDATE eti SET emp=?,qt=?,lot=?,cd=?,pc=?,ob=?,st=? WHERE id=?",
          emp, qt, Get(f, "lot"), Get(f, "cd"), Get(f, "pc"), Get(f, "ob"), st, i);
    }
    public void CopyLabels(string rec, string lig, string src, bool add)
    {
        Row s = Label(src);
        if (s == null) throw new ValueError("S\u00E9lectionnez d\u2019abord une \u00E9tiquette \u00E0 recopier.");
        var f = new Dictionary<string, string>();
        f["emp"] = s.S("emp"); f["qt"] = Convert.ToString(s.D("qt"), CultureInfo.InvariantCulture);
        f["lot"] = s.S("lot"); f["cd"] = s.S("cd"); f["pc"] = s.S("pc"); f["ob"] = s.S("ob");
        List<Row> lab = Labels(rec, lig);
        foreach (Row e in lab)
            if (e.S("id") != src && e.S("st") != "LOGIQUE" && e.S("st") != "SORTI")
                EditLabel(e.S("id"), f);
        if (add)
        {
            Row L = Line(rec, lig);
            int n = 0;
            foreach (Row e in lab) { int v; if (int.TryParse(Right3(e.S("id")), out v) && v > n) n = v; }
            n = n + 1;
            NewLabel(L, n);
            EditLabel(L.S("rec") + L.S("lig") + n.ToString("000"), f);
            X("UPDATE lig SET nb=nb+1 WHERE rec=? AND lig=?", rec, lig);
        }
    }
    static string Right3(string s) { return s.Length >= 3 ? s.Substring(s.Length - 3) : s; }
    public void DelLastLabel(string rec, string lig)
    {
        List<Row> lab = Labels(rec, lig);
        if (lab.Count == 0) throw new ValueError("Aucune \u00E9tiquette.");
        Row last = lab[lab.Count - 1];
        if (last.S("st") == "LOGIQUE" || last.S("st") == "SORTI")
            throw new ValueError("\u00C9tiquette d\u00E9j\u00E0 qualifi\u00E9e.");
        X("DELETE FROM eti WHERE id=?", last.S("id"));
        X("UPDATE lig SET nb=MAX(1,nb-1) WHERE rec=? AND lig=?", rec, lig);
    }

    // visitage / laboratoire
    public string Chrono()
    {
        long n = 0;
        long.TryParse(Cfg("chrono", "110394"), out n);
        n = n + 1;
        SetCfg("chrono", n);
        return n.ToString("000000000");
    }

    public List<IDictionary<string, object>> Lots(string rec, string lig)
    {
        var outp = new List<IDictionary<string, object>>();
        foreach (Row r in Q("SELECT * FROM lot WHERE rec=? AND lig=? ORDER BY lot", rec, lig))
        {
            var z = new Dictionary<string, object>();
            z["lot"] = r.S("lot"); z["chrono"] = r.S("chrono");
            z["v"] = SplitNonEmpty(r.S("v")); z["l"] = SplitNonEmpty(r.S("l"));
            outp.Add(z);
        }
        return outp;
    }
    static List<string> SplitNonEmpty(string s)
    {
        var l = new List<string>();
        if (!string.IsNullOrEmpty(s)) foreach (string x in s.Split(',')) if (x != "") l.Add(x);
        return l;
    }
    public bool LotsDone(string rec, string lig)
    {
        List<IDictionary<string, object>> L = Lots(rec, lig);
        if (L.Count == 0) return false;
        foreach (IDictionary<string, object> z in L)
            if (((List<string>)z["v"]).Count == 0 || ((List<string>)z["l"]).Count == 0) return false;
        return true;
    }
    public bool PreparePrint(string rec, string lig)
    {
        List<Row> lab = Labels(rec, lig);
        if (lab.Count == 0)
            throw new ValueError("Aucune \u00E9tiquette : cliquez d\u2019abord sur \u00AB Mise en Stock RECEPTION \u00BB.");
        foreach (Row e in lab)
            if (string.IsNullOrEmpty(e.S("emp")) || e.D("qt") <= 0)
                throw new ValueError("Renseignez l\u2019emplacement et la longueur de chaque \u00E9tiquette (double-clic sur Emplacement).");
        X("UPDATE eti SET lot='1' WHERE rec=? AND lig=? AND (lot IS NULL OR lot='')", rec, lig);
        X("UPDATE eti SET st='LABOET' WHERE rec=? AND lig=? AND st='NRECEP'", rec, lig); // r\u00E9ception \u2192 LABO ET
        var lotsSet = new List<string>();
        foreach (Row e in lab)
        {
            string lot = string.IsNullOrEmpty(e.S("lot")) ? "1" : e.S("lot");
            if (!lotsSet.Contains(lot)) lotsSet.Add(lot);
        }
        lotsSet.Sort();
        foreach (string lot in lotsSet)
            if (Q("SELECT 1 FROM lot WHERE rec=? AND lig=? AND lot=?", rec, lig, lot).Count == 0)
                X("INSERT INTO lot VALUES(?,?,?,?,?,?)", rec, lig, lot, Chrono(), "", "");
        return LotsDone(rec, lig);
    }
    public bool SelectLabel(string rec, string lig, string lot, string tab, string eid)
    {
        Row e = Label(eid);
        if (e == null || e.S("rec") != rec || e.S("lig") != lig ||
            (string.IsNullOrEmpty(e.S("lot")) ? "1" : e.S("lot")) != lot)
            throw new ValueError("Cette \u00E9tiquette n\u2019appartient pas \u00E0 ce lot.");
        bool was = LotsDone(rec, lig);
        string col = tab == "v" ? "v" : "l";
        List<Row> cur0 = Q("SELECT " + col + " c FROM lot WHERE rec=? AND lig=? AND lot=?", rec, lig, lot);
        List<string> cur = SplitNonEmpty(cur0.Count > 0 ? cur0[0].S("c") : "");
        if (!cur.Contains(eid)) cur.Add(eid);
        X("UPDATE lot SET " + col + "=? WHERE rec=? AND lig=? AND lot=?", string.Join(",", cur.ToArray()), rec, lig, lot);
        bool done = LotsDone(rec, lig);
        if (done && !was)
        {
            X("UPDATE eti SET st='LOGIQUE',ts=? WHERE rec=? AND lig=?", NowTs(), rec, lig);
            Log("Qualification r\u00E9ception " + rec + " ligne " + lig + " : \u00E9tiquettes en stock logique");
        }
        return done && !was;
    }
    public void ClearSelection(string rec, string lig, string lot, string tab)
    {
        string col = tab == "v" ? "v" : "l";
        X("UPDATE lot SET " + col + "='' WHERE rec=? AND lig=? AND lot=?", rec, lig, lot);
    }

    // consultation
    public List<IDictionary<string, object>> Consult(IDictionary<string, string> f)
    {
        var w = new List<string>(); var a = new List<object>();
        foreach (string[] ck in new[] { new[] { "dn", "cl" }, new[] { "rf", "rf" }, new[] { "co", "co" }, new[] { "fo", "fo" } })
        {
            string v = FGet(f, ck[1]).Trim().ToUpperInvariant();
            if (v != "") { w.Add(ck[0] + "=?"); a.Add(v); }
        }
        if (FGet(f, "nl").Trim() != "") { w.Add("id LIKE ?"); a.Add("%" + f["nl"].Trim() + "%"); }
        if (FGet(f, "of").Trim() != "") { w.Add("UPPER(cd)=?"); a.Add(f["of"].Trim().ToUpperInvariant()); }
        if (FGet(f, "lc").Trim() != "")
        {
            var ofs = new List<string>();
            foreach (Row c in Q("SELECT n FROM cmd"))
                if ((OfdGet(c.S("n")).ContainsKey("lancement") ? Convert.ToString(OfdGet(c.S("n"))["lancement"]) : "").ToUpperInvariant() == f["lc"].Trim().ToUpperInvariant())
                    ofs.Add(c.S("n"));
            if (ofs.Count > 0)
            {
                var qs = new List<string>();
                foreach (string o in ofs) { qs.Add("?"); a.Add(o); }
                w.Add("cd IN (" + string.Join(",", qs.ToArray()) + ")");
            }
            else w.Add("0");
        }
        if (FGet(f, "tp", "Tous") != "Tous") { w.Add("st=?"); a.Add(f["tp"]); }
        var ty = new List<string>();
        if (FGet(f, "g", "1") != "0") ty.Add("Galon et bande");
        if (FGet(f, "f", "1") != "0") ty.Add("Fournitures");
        if (FGet(f, "m", "1") != "0") ty.Add("Mati\u00E8re");
        if (ty.Count > 0)
        {
            var qs = new List<string>();
            foreach (string t in ty) { qs.Add("?"); a.Add(t); }
            w.Add("ty IN (" + string.Join(",", qs.ToArray()) + ")");
        }
        else w.Add("0");
        var g = new List<IDictionary<string, object>>();
        var idx = new Dictionary<string, IDictionary<string, object>>();
        foreach (Row e in Q("SELECT * FROM eti WHERE " + string.Join(" AND ", w.ToArray()) + " ORDER BY ts,id", a.ToArray()))
        {
            string key = e.S("rf") + "|" + e.S("co") + "|" + e.S("fo");
            IDictionary<string, object> r;
            if (!idx.TryGetValue(key, out r))
            {
                r = new Dictionary<string, object>();
                r["rf"] = e.S("rf"); r["co"] = e.S("co"); r["fo"] = e.S("fo"); r["un"] = e.S("un");
                r["d"] = e.S("d"); r["rec"] = 0.0; r["log"] = 0.0; r["res"] = 0.0;
                idx[key] = r; g.Add(r);
            }
            r["d"] = e.S("d");
            if (e.S("st") == "RECEP") r["rec"] = (double)r["rec"] + e.D("qt");
            if (e.S("st") == "LOGIQUE") r["log"] = (double)r["log"] + e.D("qt");
        }
        foreach (IDictionary<string, object> r in g)
        {
            string rf = Convert.ToString(r["rf"]), co = Convert.ToString(r["co"]);
            r["res"] = Reserved(rf, co);
            r["sur"] = Surplus(rf, co);
            r["et"] = Labo(rf, co, "LABOET");
            r["ft"] = Labo(rf, co, "LABOFT");
            r["sec"] = Secondaire(rf, co);
        }
        return g;
    }
    static string FGet(IDictionary<string, string> f, string k) { string v; return f.TryGetValue(k, out v) ? (v ?? "") : ""; }
    static string FGet(IDictionary<string, string> f, string k, string d) { string v; return f.TryGetValue(k, out v) && v != null && v != "" ? v : d; }

    // commandes OF, picking, inventaire
    public List<Row> Nom() { return Q("SELECT * FROM nom ORDER BY rf, co"); }
    public void AddNom(string rf, string co, object c)
    {
        rf = (rf ?? "").Trim().ToUpperInvariant(); co = (co ?? "").Trim().ToUpperInvariant();
        double cc = U.Num(c);
        if (rf == "" || co == "" || cc <= 0)
            throw new ValueError("R\u00E9f\u00E9rence, coloris et m\u00E8tres par pi\u00E8ce (sup\u00E9rieur \u00E0 0) sont requis.");
        X("INSERT OR REPLACE INTO nom VALUES(?,?,?)", rf, co, cc);
    }
    public void DelNom(string rf, string co) { X("DELETE FROM nom WHERE rf=? AND co=?", rf, co); }

    public NeedResult Need(IDictionary<string, double> q)
    {
        var res = new NeedResult();
        foreach (Row n in Nom())
        {
            double s = 0;
            foreach (Sz t in Sizes()) s += DGet(q, t.T) * n.D("c") * t.C;
            res.Rows.Add(new Row(new[] { "rf", "co", "p", "q" },
                new object[] { n.S("rf"), n.S("co"), 0.0, Math.Round(s, 3) }));
        }
        foreach (double v in q.Values) res.Pcs += v;
        return res;
    }
    static double DGet(IDictionary<string, double> d, string k) { double v; return d.TryGetValue(k, out v) ? v : 0; }

    public double Logique(string rf, string co)
    {
        List<Row> r = Q("SELECT COALESCE(SUM(qt),0) s FROM eti WHERE st='LOGIQUE' AND rf=? AND co=?", rf, co);
        return r[0].D("s");
    }
    public double Reserved(string rf, string co)
    {
        List<Row> r = Q("SELECT COALESCE(SUM(MAX(0, l.q - l.p)),0) s FROM cmdl l JOIN cmd c ON c.n=l.n " +
                        "WHERE c.st<>'TRAIT\u00C9' AND l.rf=? AND l.co=?", rf, co);
        return r[0].D("s");
    }
    public double Surplus(string rf, string co)
    {
        List<Row> r = Q("SELECT COALESCE(SUM(MAX(0, l.p - l.q)),0) s FROM cmdl l JOIN cmd c ON c.n=l.n " +
                        "WHERE l.rf=? AND l.co=?", rf, co);
        return r[0].D("s");
    }
    public double Secondaire(string rf, string co)
    {
        List<Row> t = Q("SELECT ty FROM eti WHERE rf=? AND co=? LIMIT 1", rf, co);
        if (t.Count > 0 && t[0].S("ty") != "Mati\u00E8re") return Surplus(rf, co);
        return 0;
    }
    public double Labo(string rf, string co, string ty)
    {
        List<Row> r = Q("SELECT COALESCE(SUM(qt),0) s FROM eti WHERE st=? AND rf=? AND co=?", ty, rf, co);
        return r[0].D("s");
    }
    public List<IDictionary<string, object>> Moves(string rf, string co, string of)
    {
        var outp = new List<IDictionary<string, object>>();
        foreach (Row r in Q("SELECT ts, msg FROM hist WHERE msg LIKE 'MVT|%' ORDER BY rowid DESC"))
        {
            string[] p = r.S("msg").Split('|');
            if (p.Length < 8) continue;
            if (rf != null && p[3] != rf) continue;
            if (co != null && p[4] != co) continue;
            if (of != null && p[2] != of) continue;
            var m = new Dictionary<string, object>();
            m["ts"] = r.S("ts"); m["of"] = p[2]; m["rf"] = p[3]; m["co"] = p[4]; m["eid"] = p[5];
            m["qt"] = U.Num(p[6]);
            m["un"] = p.Length > 7 ? p[7] : "";
            m["emp"] = p.Length > 8 ? p[8] : "";
            m["lz"] = p.Length > 9 ? U.Num(p[9]) : 0;
            outp.Add(m);
        }
        return outp;
    }
    public List<IDictionary<string, object>> Moves(string rf, string co) { return Moves(rf, co, null); }
    public List<IDictionary<string, object>> Moves() { return Moves(null, null, null); }

    public double Laize(Row e)
    {
        Row L = Line(e.S("rec"), e.S("lig"));
        return L != null && L.D("qu") != 0 ? L.D("qu") : e.D("an");
    }
    public string ChronoOf(Row e)
    {
        List<Row> r = Q("SELECT chrono FROM lot WHERE rec=? AND lig=? AND lot=?", e.S("rec"), e.S("lig"),
                        string.IsNullOrEmpty(e.S("lot")) ? "1" : e.S("lot"));
        return r.Count > 0 ? r[0].S("chrono") : "";
    }
    public void SetLabo(string eid, string st)
    {
        Row e = Label(eid);
        if (e == null) throw new ValueError("\u00C9tiquette introuvable.");
        if (e.S("st") != "LOGIQUE" && e.S("st") != "LABOET" && e.S("st") != "LABOFT")
            throw new ValueError("Seule une \u00E9tiquette en stock logique ou au labo peut changer d\u2019\u00E9tat.");
        X("UPDATE eti SET st=? WHERE id=?", st, eid);
        Log("Etiquette " + eid + " : passage en \u00E9tat " + st);
    }
    public void LaboLogique(string eid)
    {
        Row e = Label(eid);
        if (e == null || (e.S("st") != "LABOET" && e.S("st") != "LABOFT"))
            throw new ValueError("S\u00E9lectionnez une \u00E9tiquette en Retour Labo (LABOET / LABOFT).");
        X("UPDATE eti SET st='LOGIQUE', ts=? WHERE id=?", NowTs(), eid);
        Log("Retour Labo : \u00E9tiquette " + eid + " pass\u00E9e en stock logique");
    }
    static double NowTs() { return (DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalSeconds; }

    public IDictionary<string, object> OfdGet(string n)
    {
        object d = Json.Parse(Cfg("ofd:" + n) ?? "{}");
        return d as IDictionary<string, object> ?? new Dictionary<string, object>();
    }
    public void OfdSet(string n, IDictionary<string, object> d) { SetCfg("ofd:" + n, Json.DumpU(d)); }
    public static string DGet(IDictionary<string, object> d, string k, string dflt)
    {
        object v; return d.TryGetValue(k, out v) && v != null ? Convert.ToString(v, CultureInfo.InvariantCulture) : dflt;
    }

    // Sortie mati\u00E8re OF : lancements
    public List<IDictionary<string, object>> Lancements()
    {
        var rows = new List<IDictionary<string, object>>();
        foreach (Row c in Q("SELECT * FROM cmd ORDER BY d DESC, n"))
        {
            IDictionary<string, object> d = OfdGet(c.S("n"));
            List<Row> lines = Q("SELECT * FROM cmdl WHERE n=?", c.S("n"));
            double reste = 0, sur = 0;
            foreach (Row l in lines) { reste += Math.Max(0, l.D("q") - l.D("p")); sur += Math.Max(0, l.D("p") - l.D("q")); }
            string etat = reste <= .0005 && sur <= .0005 ? "Complet" : (reste > .0005 ? "A compl\u00E9ter" : "A sortir");
            var r = new Dictionary<string, object>();
            r["n"] = c.S("n"); r["lancement"] = DGet(d, "lancement", c.S("n")); r["date"] = c.S("d");
            r["etat"] = etat; r["pcs"] = c.L("pcs"); r["st"] = c.S("st"); r["reste"] = reste; r["sur"] = sur;
            r["obs"] = DGet(d, "commentaire", ""); r["dest"] = DGet(d, "atelier", "");
            r["tiers"] = DGet(d, "tiers", ""); r["regroup"] = DGet(d, "regroupement", "");
            r["modele"] = DGet(d, "modele", "");
            rows.Add(r);
        }
        return rows;
    }

    public string Token()
    {
        string t = Cfg("pair_token");
        if (t == "")
        {
            long ms = DateTime.UtcNow.Ticks / TimeSpan.TicksPerMillisecond;
            t = ms.ToString("x") + ((DateTime.UtcNow.Ticks * 7919 / TimeSpan.TicksPerMillisecond) % 99991).ToString("00000");
            SetCfg("pair_token", t);
        }
        return t;
    }

    // Mod\u00E8les techniques & nomenclature (stock\u00E9s en JSON dans cfg)
    public List<object[]> Modeles() // [tiers, ref, data]
    {
        var outp = new List<object[]>();
        foreach (Row kv in Q("SELECT k, v FROM cfg WHERE k LIKE 'mdl:%'"))
        {
            IDictionary<string, object> d = Json.Parse(kv.S("v")) as IDictionary<string, object>;
            if (d == null) continue;
            outp.Add(new object[] { DGet(d, "tiers", ""), DGet(d, "ref", kv.S("k").Split(':')[2]), d });
        }
        return outp;
    }
    public IDictionary<string, object> ModeleGet(string tiers, string rf)
    {
        string k = "mdl:" + tiers + ":" + rf;
        IDictionary<string, object> d = Json.Parse(Cfg(k) ?? "null") as IDictionary<string, object>;
        if (d == null)
        {
            d = new Dictionary<string, object>();
            d["tiers"] = tiers; d["ref"] = rf; d["coloris"] = new List<object>();
        }
        return d;
    }
    public void ModeleSet(string tiers, string rf, IDictionary<string, object> d)
    {
        SetCfg("mdl:" + tiers + ":" + rf, Json.DumpU(d));
    }
    public IDictionary<string, object> NomenGet(string tiers, string rf)
    {
        string k = "noml:" + tiers + ":" + rf;
        IDictionary<string, object> d = Json.Parse(Cfg(k) ?? "null") as IDictionary<string, object>;
        if (d == null) { d = new Dictionary<string, object>(); d["lignes"] = new List<object>(); }
        return d;
    }
    public void NomenSet(string tiers, string rf, IDictionary<string, object> d)
    {
        SetCfg("noml:" + tiers + ":" + rf, Json.DumpU(d));
    }

    // Param\u00E9trage & r\u00E9sultats des tests Labo
    public IDictionary<string, object> LaboParam(string rf, string tiers)
    {
        foreach (Row kv in Q("SELECT k, v FROM cfg WHERE k LIKE 'labo:%'"))
        {
            string ku = kv.S("k").ToUpperInvariant();
            if (ku.EndsWith(":" + rf.ToUpperInvariant()) || ku.EndsWith(":" + rf.ToUpperInvariant() + " "))
            {
                IDictionary<string, object> d = Json.Parse(kv.S("v")) as IDictionary<string, object>;
                if (d != null) return d;
            }
        }
        var d0 = new Dictionary<string, object>();
        d0["tests"] = new List<object>(); d0["mesures"] = new List<object>();
        return d0;
    }
    public void LaboParamSet(string rf, string tiers, IDictionary<string, object> d)
    {
        SetCfg("labo:" + tiers + ":" + rf, Json.DumpU(d));
    }
    public IDictionary<string, object> LaboRes(string eid)
    {
        IDictionary<string, object> d = Json.Parse(Cfg("labores:" + eid) ?? "null") as IDictionary<string, object>;
        if (d == null) { d = new Dictionary<string, object>(); d["tests"] = new List<object>(); }
        return d;
    }
    public void LaboResSet(string eid, IDictionary<string, object> d)
    {
        SetCfg("labores:" + eid, Json.DumpU(d));
    }

    // Fabrication du Lancement
    public long NextNum(string key, long start)
    {
        long n = 0; long.TryParse(Cfg(key, Convert.ToString(start)), out n);
        n = n + 1;
        SetCfg(key, n);
        return n;
    }
    public string NewLancement(List<string> ofs, string tiers, string prefix)
    {
        string key = prefix == "LT" ? "num_lt" : (prefix == "LP" ? "num_lp" : "num_l");
        long start = prefix == "LT" ? 1000 : (prefix == "LP" ? 2000 : 44726);
        long n = NextNum(key, start);
        string lan = prefix + n;
        foreach (string of in ofs)
        {
            IDictionary<string, object> d = OfdGet(of);
            d["lancement"] = lan;
            if (tiers != "") d["tiers"] = tiers;
            OfdSet(of, d);
        }
        Log("Lancement " + lan + " cr\u00E9\u00E9 automatiquement pour " + ofs.Count + " OF : " + string.Join(", ", ofs.ToArray()));
        return lan;
    }
    public void AttachOf(string lan, List<string> ofs, string tiers)
    {
        foreach (string of in ofs)
        {
            IDictionary<string, object> d = OfdGet(of);
            d["lancement"] = lan;
            if (tiers != "") d["tiers"] = tiers;
            OfdSet(of, d);
        }
        Log("OF " + string.Join(", ", ofs.ToArray()) + " rattach\u00E9(s) au lancement " + lan);
    }
    public List<Row> OfsDisponibles() { return Q("SELECT * FROM cmd WHERE st<>'TRAIT\u00C9' ORDER BY n"); }
    public List<Row> Cmds() { return Q("SELECT * FROM cmd ORDER BY rowid DESC"); }

    public void CreateCmd(string n, IDictionary<string, double> q)
    {
        n = (n ?? "").Trim().ToUpperInvariant();
        NeedResult nr = Need(q);
        double pcs = nr.Pcs; List<Row> rows = nr.Rows;
        if (n == "") throw new ValueError("Renseignez le num\u00E9ro d\u2019OF.");
        if (pcs <= 0) throw new ValueError("Saisissez au moins une quantit\u00E9.");
        if (rows.Count == 0) throw new ValueError("La nomenclature est vide : ajoutez au moins une mati\u00E8re.");
        if (Q("SELECT 1 FROM cmd WHERE n=?", n).Count > 0) throw new ValueError("Cet OF existe d\u00E9j\u00E0.");
        var qd = new Dictionary<string, object>();
        foreach (KeyValuePair<string, double> kv in q) qd[kv.Key] = kv.Value;
        X("INSERT INTO cmd VALUES(?,?,?,?,?)", n, (long)pcs, "\u00C0 PR\u00C9PARER", U.TodayFr(), Json.Dump(qd));
        foreach (Row r in rows)
            X("INSERT INTO cmdl VALUES(?,?,?,?,0)", n, r.S("rf"), r.S("co"), r.D("q"));
        Log("Commande " + n + " cr\u00E9\u00E9e (" + pcs.ToString("0", CultureInfo.InvariantCulture) + " pi\u00E8ces)");
    }
    public void DelCmd(string n)
    {
        List<Row> c = Q("SELECT st FROM cmd WHERE n=?", n);
        if (c.Count > 0 && c[0].S("st") != "\u00C0 PR\u00C9PARER")
            throw new ValueError("Une commande d\u00E9j\u00E0 en pr\u00E9paration ne peut pas \u00EAtre supprim\u00E9e.");
        X("DELETE FROM cmdl WHERE n=?", n);
        X("DELETE FROM cmd WHERE n=?", n);
        Log("Commande " + n + " supprim\u00E9e");
    }
    public List<Row> Picks()
    {
        return Q("SELECT l.n, l.rf, l.co, l.q, l.p FROM cmdl l JOIN cmd c ON c.n=l.n " +
                 "WHERE l.q - l.p > 0.0005 ORDER BY l.n, l.rf");
    }
    public List<Row> Suggest(string rf, string co)
    {
        return Q("SELECT * FROM eti WHERE st='LOGIQUE' AND rf=? AND co=? ORDER BY ts, id LIMIT 5", rf, co);
    }
    public double PickOut(string n, string rf, string co, string eid, string emp)
    {
        List<Row> l = Q("SELECT * FROM cmdl WHERE n=? AND rf=? AND co=?", n, rf, co);
        Row it = Label(eid);
        if (l.Count == 0) throw new ValueError("Ligne de commande introuvable.");
        if (it == null || it.S("st") != "LOGIQUE")
            throw new ValueError("\u00C9tiquette introuvable ou d\u00E9j\u00E0 sortie.");
        if (it.S("rf") != rf || it.S("co") != co)
            throw new ValueError("Cette \u00E9tiquette est " + it.S("rf") + " " + it.S("co") + ", pas " + rf + " " + co + ".");
        if ((emp ?? "").Trim() != "" && (emp ?? "").Trim().ToUpperInvariant() != it.S("emp"))
            throw new ValueError("Mauvais emplacement : l\u2019\u00E9tiquette est en " + it.S("emp") + ".");
        double q = Math.Min(it.D("qt"), Math.Round(l[0].D("q") - l[0].D("p"), 3));
        double left = Math.Round(it.D("qt") - q, 3);
        X("UPDATE eti SET qt=?, st=? WHERE id=?", left, left <= .0004 ? "SORTI" : "LOGIQUE", eid);
        X("UPDATE cmdl SET p=ROUND(p+?,3) WHERE n=? AND rf=? AND co=?", q, n, rf, co);
        bool done = Q("SELECT 1 FROM cmdl WHERE n=? AND q - p > 0.0005", n).Count == 0;
        X("UPDATE cmd SET st=? WHERE n=?", done ? "TRAIT\u00C9" : "PARTIEL", n);
        Row L = Line(it.S("rec"), it.S("lig"));
        double lz = L != null && L.D("qu") != 0 ? L.D("qu") : 0;
        Log("MVT|SORTIE|" + n + "|" + rf + "|" + co + "|" + eid + "|" + U.F3(q) + "|" + it.S("un") + "|" + it.S("emp") + "|" + U.F3(lz));
        Log("Sortie " + U.F3(q) + " " + it.S("un") + " " + rf + " " + co + " pour " + n + " (\u00E9tiquette " + eid + ")");
        return q;
    }
    public List<Row> Inventory() { return Q("SELECT * FROM eti WHERE st='LOGIQUE' ORDER BY emp, id"); }
    public int ApplyCount(IDictionary<string, string> counts)
    {
        int k = 0;
        foreach (KeyValuePair<string, string> kv in counts)
        {
            Row e = Label(kv.Key); double n = U.Num(kv.Value);
            if (e != null && Math.Abs(n - e.D("qt")) > .0004)
            {
                Log("Inventaire " + kv.Key + " : " + U.F3(e.D("qt")) + " \u2192 " + U.F3(n));
                X("UPDATE eti SET qt=?, st=? WHERE id=?", n, n > 0 ? "LOGIQUE" : "SORTI", kv.Key);
                k++;
            }
        }
        return k;
    }
}
}

// ===== part03_ui.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Framework UI (port de Grid / Win / Code / widgets) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

public class GRow
{
    public string Id; public string[] V; public bool Nr;
    public GRow(string id, string[] v, bool nr) { Id = id; V = v; Nr = nr; }
}

public class Grid : UserControl
{
    public DataGridView t;
    public string Cur;
    public Action<string> OnSel;
    public Action OnDbl;
    bool syncing;

    public Grid(Control parent, string[] cols, int[] widths, int rows,
                Action<string> onSel, Action onDbl, int[] right)
    {
        BackColor = Color.White;
        t = new DataGridView();
        t.ReadOnly = true; t.AllowUserToAddRows = false; t.AllowUserToDeleteRows = false;
        tallowuser(); t.RowHeadersVisible = false; t.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        t.MultiSelect = false; t.BackgroundColor = Color.White; t.BorderStyle = BorderStyle.None;
        t.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.None;
        t.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(0x2f, 0x5f, 0x95);
        t.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
        t.ColumnHeadersDefaultCellStyle.Font = C.FONTB;
        t.EnableHeadersVisualStyles = false;
        t.DefaultCellStyle.Font = C.FONT;
        t.RowTemplate.Height = 20;
        t.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
        t.Dock = DockStyle.Fill;
        for (int i = 0; i < cols.Length; i++)
        {
            var c = new DataGridViewTextBoxColumn();
            c.Name = "c" + i; c.HeaderText = cols[i]; c.Width = widths[i];
            c.SortMode = DataGridViewColumnSortMode.NotSortable;
            if (right != null && Array.IndexOf(right, i) >= 0) c.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            t.Columns.Add(c);
        }
        t.SelectionChanged += delegate
        {
            if (syncing) return;
            string id = CurRowId();
            bool ch = id != Cur;
            Cur = id;
            if (ch && OnSel != null) OnSel(Cur);
        };
        t.CellDoubleClick += delegate { if (OnDbl != null) OnDbl(); };
        Controls.Add(t);
        Height = rows * 20 + 24;
        if (parent != null) parent.Controls.Add(this);
    }
    void tallowuser() { t.AllowUserToResizeRows = false; }
    public string CurRowId()
    {
        if (t.CurrentRow == null) return null;
        return Convert.ToString(t.CurrentRow.Tag);
    }
    public RowCellColor ColorOf(bool nr, bool even)
    {
        if (nr) return even ? new RowCellColor(Color.FromArgb(0xc9, 0xc9, 0xea)) : new RowCellColor(Color.FromArgb(0xf9, 0xcd, 0xcd));
        return even ? new RowCellColor(Color.FromArgb(0xff, 0xff, 0xdf)) : new RowCellColor(Color.FromArgb(0xea, 0xf1, 0xfb));
    }
    public void Fill(List<GRow> rows)
    {
        string prev = Cur;
        syncing = true;
        t.SuspendLayout();
        t.Rows.Clear();
        for (int i = 0; i < rows.Count; i++)
        {
            GRow gr = rows[i];
            int idx = t.Rows.Add(gr.V);
            DataGridViewRow dr = t.Rows[idx];
            dr.Tag = gr.Id; dr.Selected = false;
            DataGridViewRow row = t.Rows[idx];
            Color bc = ColorOf(gr.Nr, i % 2 == 0).Color;
            foreach (DataGridViewCell cell in dr.Cells) cell.Style.BackColor = bc;
        }
        t.ResumeLayout();
        bool found = false;
        if (prev != null)
            foreach (DataGridViewRow r in t.Rows)
                if (Convert.ToString(r.Tag) == prev) { r.Selected = true; found = true; break; }
        if (!found) Cur = CurRowId();
        else Cur = prev;
        syncing = false;
        if (found && OnSel != null) OnSel(Cur);
    }
    public void Fill(params GRow[] rows) { Fill(new List<GRow>(rows)); }

    // pour RegroupFourn.impr : valeurs de la ligne courante
    public string[] CurVals()
    {
        if (t.CurrentRow == null) return new string[0];
        var v = new string[t.Columns.Count];
        for (int i = 0; i < v.Length; i++) v[i] = Convert.ToString(t.CurrentRow.Cells[i].Value);
        return v;
    }
    public List<string[]> AllVals()
    {
        var l = new List<string[]>();
        foreach (DataGridViewRow r in t.Rows)
        {
            var v = new string[t.Columns.Count];
            for (int i = 0; i < v.Length; i++) v[i] = Convert.ToString(r.Cells[i].Value);
            l.Add(v);
        }
        return l;
    }
    public void SelectId(string id, bool see = true)
    {
        foreach (DataGridViewRow r in t.Rows)
            if (Convert.ToString(r.Tag) == id)
            {
                r.Selected = true; t.CurrentCell = r.Cells[0];
                if (see) t.FirstDisplayedScrollingRowIndex = Math.Max(0, r.Index - 3);
                return;
            }
    }
    public bool Exists(string id)
    {
        foreach (DataGridViewRow r in t.Rows) if (Convert.ToString(r.Tag) == id) return true;
        return false;
    }
}

public class RowCellColor { public Color Color; public RowCellColor(Color c) { Color = c; } }

// \u2500\u2500 widgets utilitaires \u2500\u2500
public static class UI
{
    public static Label Lab(Control p, string text)
    {
        var l = new Label(); l.Text = text; l.BackColor = Color.White; l.TextAlign = ContentAlignment.MiddleLeft;
        l.AutoSize = true; l.Font = C.FONT;
        if (p != null) p.Controls.Add(l);
        return l;
    }
    public static TextBox Ent(int wchars)
    {
        var e = new TextBox(); e.Font = C.FONT; e.BorderStyle = BorderStyle.FixedSingle;
        e.Width = wchars * 7 + 10;
        return e;
    }
    public static Button Btn(string text, EventHandler cmd, bool red, int w)
    {
        var b = new Button(); b.Text = text; b.Width = w * 7 + 14; b.Height = 28;
        b.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0); b.FlatStyle = FlatStyle.Popup;
        b.ForeColor = red ? Color.FromArgb(0xd9, 0x34, 0x2b) : Color.Black;
        b.Font = C.FONTB; b.TextAlign = ContentAlignment.MiddleLeft;
        if (cmd != null) b.Click += cmd;
        return b;
    }
    public static ComboBox Combo(params string[] values)
    {
        var cb = new ComboBox(); cb.DropDownStyle = ComboBoxStyle.DropDownList;
        cb.Font = C.FONT; cb.Width = 130;
        foreach (string v in values) cb.Items.Add(v);
        if (values.Length > 0) cb.SelectedIndex = 0;
        return cb;
    }
    public static CheckBox Check(string text)
    {
        var c = new CheckBox(); c.Text = text; c.Font = C.FONT; c.BackColor = Color.White; c.AutoSize = true;
        return c;
    }
    public static GroupBox Frame(string text)
    {
        var g = new GroupBox(); g.Text = text; g.Font = C.FONT; g.BackColor = Color.White;
        return g;
    }
    public static TableLayoutPanel Tlp(int cols, params float[] pct)
    {
        var t = new TableLayoutPanel(); t.BackColor = Color.White; t.AutoSize = true;
        t.ColumnCount = cols;
        for (int i = 0; i < cols; i++) t.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        return t;
    }
    public static TextBox Text(int w, int h)
    {
        var t = new TextBox(); t.Multiline = true; t.Font = C.FONT;
        t.Width = w * 7 + 10; t.Height = h * 16 + 6; t.BorderStyle = BorderStyle.FixedSingle;
        return t;
    }
    public static Label InfoLbl(string text)
    {
        var l = new Label(); l.Text = text; l.Font = C.FONT; l.BackColor = Color.White;
        l.BorderStyle = BorderStyle.Fixed3D; l.AutoSize = true;
        return l;
    }
    public static Image LogoImage()
    {
        try
        {
            byte[] b = Convert.FromBase64String(C.LOGO_PNG_B64);
            using (var ms = new System.IO.MemoryStream(b)) return Image.FromStream(ms);
        }
        catch { return null; }
    }
}

// \u2500\u2500 S\u00E9lecteur de code (port de pick_code) \u2500\u2500
public class PickCode
{
    public static string Show(Control parent, Store S, string kind)
    {
        string res = "";
        Form w = new Form();
        w.Text = "S\u00E9lection : " + C.NAMES[kind];
        w.StartPosition = FormStartPosition.CenterParent;
        w.Size = new Size(460, 380); w.BackColor = Color.White;
        var g = new Grid(null, new[] { "Code", "Libell\u00E9" }, new[] { 120, 300 }, 8, null, null, null);
        g.Dock = DockStyle.Fill;
        var rows = new List<GRow>();
        foreach (Row r in S.Tiers(kind)) rows.Add(new GRow(r.S("code"), new[] { r.S("code"), r.S("lib") }, false));
        g.Fill(rows);
        w.Controls.Add(g);
        var b = UI.Btn("S\u00E9lectionner", delegate { if (g.Cur != null) { res = g.Cur; w.Close(); } }, false, 14);
        b.Dock = DockStyle.Bottom; b.Height = 34; w.Controls.Add(b);
        w.ShowDialog(parent.FindForm());
        return res;
    }
}

// \u2500\u2500 Champ code + loupe + libell\u00E9 automatique (port de Code) \u2500\u2500
public class CodeField
{
    App win; string kind; TextBox var; Label d;
    public CodeField(Control p, App win, string kind, string text, TextBox var, int row, int w)
    {
        this.win = win; this.kind = kind; this.var = var;
        var tlp = p as TableLayoutPanel;
        var l = UI.Lab(null, text);
        var pick = UI.Btn("\uD83D\uDD0D", delegate { Pick(); }, false, 3);
        pick.Width = 36;
        d = new Label(); d.Text = ""; d.BackColor = Color.FromArgb(0xf3, 0xf3, 0xf3);
        d.BorderStyle = BorderStyle.Fixed3D; d.TextAlign = ContentAlignment.MiddleLeft;
        d.Width = 250; d.Height = 22; d.Font = C.FONT;
        if (tlp != null)
        {
            tlp.Controls.Add(l, 0, row); tlp.Controls.Add(var, 1, row);
            tlp.Controls.Add(pick, 2, row); tlp.Controls.Add(d, 3, row);
        }
        else { p.Controls.Add(l); p.Controls.Add(var); p.Controls.Add(pick); p.Controls.Add(d); }
        var.TextChanged += delegate { Upd(); };
        Upd();
    }
    void Upd() { if (S != null) d.Text = S.Lib(kind, var.Text); }
    Store S { get { return win != null ? win.S : null; } }
    void Pick()
    {
        string c = PickCode.Show(var, win.S, kind);
        if (c != "") var.Text = c;
    }
}

// \u2500\u2500 Fen\u00EAtre de base (port de Win) \u2500\u2500
public class Win : Form
{
    public App App; public Store S;
    public Panel Body = new Panel();

    public Win(App app, string title, string size)
    {
        App = app; S = app.S;
        Text = title; BackColor = Color.White;
        if (size != null)
        {
            string[] p = size.Split('x');
            int wd, ht;
            int.TryParse(p[0], out wd); int.TryParse(p[p.Length - 1], out ht);
            ClientSize = new Size(wd, ht);
        }
        StartPosition = FormStartPosition.CenterParent;
        Body.Dock = DockStyle.Fill; Body.BackColor = Color.White;
        Controls.Add(Body);
        FormClosed += delegate { try { App.Refresh(); } catch { } };
    }
}
}

// ===== part04_reception.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Nouvelle r\u00E9ception / \u00C9tiquette / Qualification / VisLab / Impression \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

using DictS = System.Collections.Generic.Dictionary<string, string>;
using DictO = System.Collections.Generic.IDictionary<string, object>;

public class NewRec : Win
{
    public TextBox qt, tr, lb, ca, cr, dt;
    public CheckBox ir, pd, ra;
    TextBox cm;

    public NewRec(App app) : base(app, "Nouvelle r\u00E9ception", "780x520")
    {
        var top = new FlowLayoutPanel { BackColor = Color.White, Dock = DockStyle.Top, Height = 36 };
        UI.Lab(top, "Recherche rapide");
        qt = UI.Ent(14); top.Controls.Add(qt);
        top.Controls.Add(UI.Btn("Rechercher \uD83D\uDD0D", delegate { Search(); }, false, 14));
        var row = new Panel { Dock = DockStyle.Fill, BackColor = Color.White };
        var right = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Width = 170, Dock = DockStyle.Right, BackColor = Color.White, Anchor = AnchorStyles.Top };
        var left = UI.Frame("");
        left.Width = 580; left.Height = 430; left.Dock = DockStyle.Fill;
        row.Controls.Add(left); row.Controls.Add(right);
        Body.Controls.Add(top); Body.Controls.Add(row);

        var tlp = new TableLayoutPanel { BackColor = Color.White, AutoSize = true, Dock = DockStyle.Top, ColumnCount = 4 };
        tlp.Controls.Add(new Control(), 0, 0); // placeholder
        left.Controls.Add(tlp);
        var cf = new CodeField(tlp, app, "transporteur", "Transporteur (*)", tr = UI.Ent(10), 0, 10);
        UI.Lab(null, "").Dispose();
        AddRow(tlp, 1, "Libell\u00E9 (*)", lb = UI.Ent(50));
        AddRow2(tlp, 2, "Nbre Colis annonc\u00E9s (*)", ca = UI.Ent(8), "Date", dt = UI.Ent(12));
        AddRow2(tlp, 3, "Nbre Colis re\u00E7us (*)", cr = UI.Ent(8), "", null);
        ir = UI.Check("Indicateur r\u00E9serve"); pd = UI.Check("Indicateur port d\u00FB"); ra = UI.Check("Retour Atelier");
        tlp.RowCount = Math.Max(tlp.RowCount, 4); tlp.Controls.Add(ir, 1, 4); tlp.Controls.Add(pd, 1, 5); tlp.Controls.Add(ra, 1, 6);
        UI.Lab(tlp, "Commentaires").ForeColor = Color.Black;
        tlp.Controls.Add(UI.Lab(null, "Commentaires"), 0, 7);
        cm = UI.Text(50, 5);
        tlp.SetColumnSpan(cm, 3);
        tlp.Controls.Add(cm, 1, 7);
        tlp.RowCount = 8;
        right.Controls.Add(UI.Btn("Enregistrer \u2714", delegate { Save(); }, false, 16));
        right.Controls.Add(UI.Btn("Nouveau \uFF0B", delegate { Reset(); }, false, 16));
        right.Controls.Add(UI.Btn("Bordereau \uD83D\uDDA8", delegate { Slip(); }, false, 16));
        right.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 16));
        Reset();
    }
    static void AddRow(TableLayoutPanel t, int r, string lab, TextBox e)
    {
        t.RowCount = Math.Max(t.RowCount, r + 1);
        t.Controls.Add(UI.Lab(null, lab), 0, r); t.Controls.Add(e, 1, r);
        t.SetColumnSpan(e, 3);
    }
    static void AddRow2(TableLayoutPanel t, int r, string lab, TextBox e, string lab2, TextBox e2)
    {
        t.RowCount = Math.Max(t.RowCount, r + 1);
        t.Controls.Add(UI.Lab(null, lab), 0, r); t.Controls.Add(e, 1, r);
        if (lab2 != "") { UI.Lab(null, lab2); t.Controls.Add(UI.Lab(null, lab2), 2, r); }
        if (e2 != null) t.Controls.Add(e2, 3, r);
    }

    public void Reset()
    {
        qt.Text = DateTime.Today.ToString("yyMMdd");
        tr.Text = ""; lb.Text = ""; ca.Text = "0"; cr.Text = "0";
        dt.Text = U.TodayFr();
        ir.Checked = pd.Checked = ra.Checked = false;
        cm.Text = "";
    }
    void Search()
    {
        List<Row> r = S.Q("SELECT id FROM rec WHERE id LIKE ? ORDER BY id DESC", qt.Text.Trim() + "%");
        if (r.Count == 0) { U.Warn(this, "Aucune r\u00E9ception trouv\u00E9e."); return; }
        string rid = r[0].S("id");
        Close();
        App.ActivateDelayed(delegate { new Qualif(App, rid).Show(); });
    }
    void Save()
    {
        try
        {
            string rid = S.AddRec(tr.Text, lb.Text, ca.Text, cr.Text, dt.Text,
                                  ir.Checked ? 1 : 0, pd.Checked ? 1 : 0, ra.Checked ? 1 : 0, cm.Text.Trim());
            Close();
            App.ActivateDelayed(delegate { new Qualif(App, rid).Show(); });
        }
        catch (ValueError e) { U.Warn(this, e.Message); }
    }
    void Slip()
    {
        DictO r = new Dictionary<string, object>();
        r["id"] = "(non enregistr\u00E9e)"; r["date"] = dt.Text; r["tr"] = tr.Text; r["lb"] = lb.Text;
        r["ca"] = ca.Text; r["cr"] = cr.Text; r["cm"] = cm.Text.Trim();
        U.OpenHtml(U.SlipHtml(r, new List<Row>()));
    }
}

public class EtiDlg : Win
{
    string eid;
    public EtiDlg(App app, string eid) : base(app, "Etiquette " + eid, "480x300")
    {
        this.eid = eid;
        Row e = S.Label(eid);
        var tlp = new TableLayoutPanel { BackColor = Color.White, AutoSize = true, Dock = DockStyle.Top, ColumnCount = 2 };
        Body.Controls.Add(tlp);
        var V = new Dictionary<string, TextBox>();
        int i = 0;
        foreach (string[] kt in new[] { new[] { "emp", "Emplacement" }, new[] { "qt", "Lg/Qt\u00E9 th\u00E9orique" },
                                        new[] { "lot", "Lot" }, new[] { "cd", "Commande" },
                                        new[] { "pc", "Pi\u00E8ce" }, new[] { "ob", "Observation" } })
        {
            var t = UI.Ent(30);
            t.Text = kt[0] == "qt" ? U.F3(e.D("qt")) : (e.S(kt[0]) ?? "");
            V[kt[0]] = t;
            tlp.Controls.Add(UI.Lab(null, kt[1]), 0, i);
            tlp.Controls.Add(t, 1, i);
            i++;
        }
        var fr = new FlowLayoutPanel { BackColor = Color.White, AutoSize = true };
        Body.Controls.Add(fr);
        fr.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Ok(V); }, false, 16));
        fr.Controls.Add(UI.Btn("Annuler \u2715", delegate { Close(); }, true, 12));
    }
    void Ok(Dictionary<string, TextBox> V)
    {
        var f = new DictS();
        foreach (KeyValuePair<string, TextBox> kv in V) f[kv.Key] = kv.Value.Text;
        try { S.EditLabel(eid, f); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        Close();
    }
}

public class Qualif : Win
{
    public string rec; string lig;
    bool loading, dirty;
    public Grid g, g2;
    TabControl nb; TabPage t1, t2;
    public Dictionary<string, TextBox> V = new Dictionary<string, TextBox>();
    public Dictionary<string, CheckBox> B = new Dictionary<string, CheckBox>();
    Button bsave;
    TextBox cm; Label an, tot;

    public Qualif(App app, string rec) : base(app, "Qualification de la r\u00E9ception : " + rec, "940x740")
    {
        this.rec = rec;
        g = new Grid(Body, new[] { "Lig.", "Tiers", "Ref.", "D\u00E9signation Ref.", "Coloris", "D\u00E9signation Coloris" },
                     new[] { 50, 200, 130, 200, 100, 200 }, 5, PickLine, null, null);
        g.Dock = DockStyle.Top;
        nb = new TabControl { Dock = DockStyle.Fill };
        t1 = new TabPage("Ligne de R\u00E9ception"); t2 = new TabPage("Stock R\u00E9ception");
        nb.TabPages.Add(t1); nb.TabPages.Add(t2);
        Body.Controls.Add(nb);
        BuildLine();
        BuildStock();
        foreach (TextBox tb in V.Values) tb.TextChanged += delegate { Touch(); };
        foreach (CheckBox cb in B.Values) { cb.CheckedChanged += delegate { Touch(); }; }
        SetForm(null);
        RefreshLines();
    }

    // ---- onglet Ligne de R\u00E9ception
    void BuildLine()
    {
        var f = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Dock = DockStyle.Fill, BackColor = Color.White, AutoScroll = true };
        t1.Controls.Add(f);
        var top = UI.Tlp(4);
        f.Controls.Add(top);
        var nl = UI.Check("Non li\u00E9e \u00E0 une commande"); var lc = UI.Check("Li\u00E9e \u00E0 une commande");
        var om = UI.Check("Li\u00E9e \u00E0 un OM"); var pf = UI.Check("Li\u00E9 \u00E0 une Proforma");
        top.Controls.Add(nl, 0, 0); top.Controls.Add(lc, 1, 0);
        UI.Lab(top, "N\u00B0 de BL").Width = 120; top.Controls.Add(UI.Lab(null, "N\u00B0 de BL"), 2, 0);
        var bl = UI.Ent(14); top.Controls.Add(bl, 3, 0);
        top.Controls.Add(om, 0, 1); top.Controls.Add(pf, 1, 1);
        top.Controls.Add(UI.Lab(null, "N\u00B0 de Facture"), 2, 1);
        var fa = UI.Ent(14); top.Controls.Add(fa, 3, 1);
        top.Controls.Add(UI.Lab(null, "Date Facture"), 2, 2);
        var df = UI.Ent(12); top.Controls.Add(df, 3, 2);
        B["nl"] = nl; B["lc"] = lc; B["om"] = om; B["pf"] = pf;
        V["bl"] = bl; V["fa"] = fa; V["df"] = df;
        var g1 = UI.Frame("");
        g1.Height = 90; g1.Width = 640;
        f.Controls.Add(g1);
        var tA = new TableLayoutPanel { BackColor = Color.White, AutoSize = true, Dock = DockStyle.Fill, ColumnCount = 4 };
        g1.Controls.Add(tA);
        new CodeField(tA, App, "client", "Donneur d\u2019ordre", V["dn"] = UI.Ent(8), 0, 8);
        new CodeField(tA, App, "fournisseur", "Fournisseur", V["fo"] = UI.Ent(8), 1, 8);
        var g2 = UI.Frame("");
        g2.Height = 120; g2.Width = 640;
        f.Controls.Add(g2);
        var tB = new TableLayoutPanel { BackColor = Color.White, AutoSize = true, Dock = DockStyle.Fill, ColumnCount = 4 };
        g2.Controls.Add(tB);
        new CodeField(tB, App, "reference", "R\u00E9f\u00E9rence RFT", V["rf"] = UI.Ent(14), 0, 14);
        new CodeField(tB, App, "coloris", "Coloris", V["co"] = UI.Ent(14), 1, 14);
        new CodeField(tB, App, "marque", "Marque", V["mq"] = UI.Ent(14), 2, 14);
        var g3 = UI.Frame("");
        g3.Height = 130; g3.Width = 640;
        f.Controls.Add(g3);
        var tC = new TableLayoutPanel { BackColor = Color.White, AutoSize = true, Dock = DockStyle.Fill, ColumnCount = 6 };
        g3.Controls.Add(tC);
        tC.Controls.Add(UI.Lab(null, "Nombres d\u2019\u00E9tiquettes (*)"), 0, 0);
        V["nb"] = UI.Ent(6); tC.Controls.Add(V["nb"], 1, 0);
        tC.Controls.Add(UI.Lab(null, "Lg-Qt\u00E9 Etiq. (*)"), 0, 1);
        V["qt"] = UI.Ent(12); tC.Controls.Add(V["qt"], 1, 1);
        tC.Controls.Add(UI.Lab(null, "(en unit\u00E9 de r\u00E9cep.)"), 2, 1);
        tC.Controls.Add(UI.Lab(null, "Lg-Qt\u00E9 Etiq."), 3, 1);
        V["qu"] = UI.Ent(12); tC.Controls.Add(V["qu"], 4, 1);
        tC.Controls.Add(UI.Lab(null, "(en unit\u00E9 d\u2019utilisation)"), 5, 1);
        V["un"] = UI.Ent(6);
        new CodeField(tC, App, "unite", "Unit\u00E9 de r\u00E9ception (*)", V["un"], 2, 6);
        f.Controls.Add(UI.Btn("\u265B  Mise en Stock\nRECEPTION", delegate { MiseStock(); }, false, 18));
        var r = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Dock = DockStyle.Right, Width = 180, BackColor = Color.White };
        t1.Controls.Add(r);
        r.Controls.Add(UI.Btn("Rechercher \u270E", delegate { Reload(); }, false, 16));
        bsave = UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Save(); }, false, 16);
        r.Controls.Add(bsave);
        r.Controls.Add(UI.Btn("Nouveau \u25AF", delegate { NewL(); }, false, 16));
        r.Controls.Add(UI.Btn("Supprimer \uD83D\uDDD1", delegate { Delete(); }, false, 16));
        r.Controls.Add(UI.Btn("Bordereau \uD83D\uDDA8", delegate { Slip(); }, false, 16));
        r.Controls.Add(UI.Btn("Excel \u25A6", delegate { Excel(); }, false, 16));
    }
    void Touch()
    {
        if (!loading) { dirty = true; bsave.Enabled = true; }
    }
    public void SetForm(Row L)
    {
        loading = true;
        string[] keys = { "bl", "fa", "df", "dn", "fo", "rf", "co", "mq", "nb", "qt", "qu", "un" };
        if (L == null)
        {
            V["bl"].Text = V["fa"].Text = V["df"].Text = V["dn"].Text = V["fo"].Text =
                V["rf"].Text = V["co"].Text = V["mq"].Text = "";
            V["nb"].Text = "1"; V["qt"].Text = V["qu"].Text = "0,000"; V["un"].Text = "ML";
            B["nl"].Checked = true; B["lc"].Checked = B["om"].Checked = B["pf"].Checked = false;
        }
        else
        {
            foreach (string k in keys)
            {
                if (k == "nb") V[k].Text = Convert.ToString(L.L(k));
                else if (k == "qt" || k == "qu") V[k].Text = U.F3(L.D(k));
                else V[k].Text = L.S(k) ?? "";
            }
            B["nl"].Checked = L.L("nl") != 0; B["lc"].Checked = L.L("lc") != 0;
            B["om"].Checked = L.L("om") != 0; B["pf"].Checked = L.L("pf") != 0;
        }
        loading = false; dirty = false;
        bsave.Enabled = false;
    }
    public void RefreshLines()
    {
        var rows = new List<GRow>();
        foreach (Row l in S.Lines(rec))
            rows.Add(new GRow(l.S("lig"), new[] { l.S("lig"), string.IsNullOrEmpty(S.Lib("client", l.S("dn"))) ? l.S("dn") : S.Lib("client", l.S("dn")),
                l.S("rf"), string.IsNullOrEmpty(S.Lib("reference", l.S("rf"))) ? l.S("rf") : S.Lib("reference", l.S("rf")),
                l.S("co"), string.IsNullOrEmpty(S.Lib("coloris", l.S("co"))) ? l.S("co") : S.Lib("coloris", l.S("co")) }, false));
        g.Fill(rows);
    }
    public void PickLine(string cur)
    {
        if (cur == null) return;
        lig = cur;
        SetForm(S.Line(rec, cur));
        RefreshLabels();
    }
    void Reload()
    {
        if (lig == null) { U.Warn(this, "S\u00E9lectionnez une ligne dans la liste."); return; }
        PickLine(lig);
    }
    void NewL()
    {
        lig = null;
        SetForm(null);
        RefreshLabels();
    }
    void Save()
    {
        var f = new DictS();
        foreach (KeyValuePair<string, TextBox> kv in V) f[kv.Key] = kv.Value.Text;
        foreach (KeyValuePair<string, CheckBox> kv in B) f[kv.Key] = kv.Value.Checked ? "1" : "0";
        string newLig;
        try { newLig = S.SaveLine(rec, f, lig); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        lig = newLig;
        RefreshLines();
        PickLine(lig);
    }
    void Delete()
    {
        if (lig == null) { U.Warn(this, "S\u00E9lectionnez une ligne."); return; }
        if (!U.Ask(this, "Supprimer cette ligne et ses \u00E9tiquettes ?")) return;
        try { S.DelLine(rec, lig); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        NewL();
        RefreshLines();
    }
    void Slip() { U.OpenHtml(U.SlipHtml(S.Rec(rec), S.Lines(rec))); }
    void Excel()
    {
        U.Info(this, "Fichier cr\u00E9e :\n" + U.ExportCsv(S, rec));
    }
    void MiseStock()
    {
        if (lig == null) { U.Warn(this, "Enregistrez ou s\u00E9lectionnez d\u2019abord une ligne de r\u00E9ception."); return; }
        if (dirty) { U.Warn(this, "Enregistrez la ligne avant la mise en stock."); return; }
        S.MakeLabels(rec, lig);
        nb.SelectedTab = t2;
        RefreshLabels();
    }

    // ---- onglet Stock R\u00E9ception
    void BuildStock()
    {
        var t = t2;
        var top = new FlowLayoutPanel { Dock = DockStyle.Top, BackColor = Color.White, Height = 70 };
        t.Controls.Add(top);
        var badge = new Label { Text = "Mise en Stock RECEPTION", BackColor = Color.FromArgb(0xcf, 0xe0, 0xf5),
                                ForeColor = Color.FromArgb(0x2a, 0x5a, 0x99), Font = C.FONTB, AutoSize = true };
        top.Controls.Add(badge);
        var mid = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Width = 300, BackColor = Color.White };
        top.Controls.Add(mid);
        mid.Controls.Add(UI.Btn("Recopier la ligne en cours \u2B49", delegate { Copy(false); }, false, 32));
        mid.Controls.Add(UI.Btn("Recopier la ligne en cours (+ Qt\u00E9) \u2B49", delegate { Copy(true); }, false, 32));
        var rt = new TableLayoutPanel { BackColor = Color.White, AutoSize = true };
        top.Controls.Add(rt);
        rt.ColumnCount = 2; rt.RowCount = 2;
        var l1 = UI.Lab(null, "Lg./Qt\u00E9 Annonc\u00E9e"); l1.AutoSize = false; l1.Width = 120;
        rt.Controls.Add(l1, 0, 0);
        an = new Label { Text = "0,000", Width = 100, BorderStyle = BorderStyle.FixedSingle, Font = C.FONT, TextAlign = ContentAlignment.MiddleRight };
        rt.Controls.Add(an, 1, 0);
        var l2 = UI.Lab(null, "Lg./Qt\u00E9 Tot :"); l2.AutoSize = false; l2.Width = 120;
        rt.Controls.Add(l2, 0, 1);
        tot = new Label { Text = "0,000", Width = 100, BorderStyle = BorderStyle.FixedSingle, Font = C.FONT,
                          TextAlign = ContentAlignment.MiddleRight, BackColor = Color.Red, ForeColor = Color.White };
        rt.Controls.Add(tot, 1, 1);
        g2 = new Grid(t, new[] { "Num\u00E9ro Etiquette", "Etat", "Emplacement", "Long. Th\u00E9o.", "Lot", "Commande", "Pi\u00E8ce", "Observation" },
                      new[] { 170, 80, 120, 90, 60, 90, 70, 150 }, 9, null, Edit, new[] { 3 });
        g2.Dock = DockStyle.Fill;
        var bot = new FlowLayoutPanel { Dock = DockStyle.Bottom, BackColor = Color.White, Height = 40 };
        t.Controls.Add(bot);
        bot.Controls.Add(UI.Btn("Imprimer les \u00E9tiquettes \u25A5", delegate { Imprimer(); }, false, 24));
        bot.Controls.Add(UI.Btn("Modifier l\u2019\u00E9tiquette \u270E", delegate { Edit(); }, false, 22));
        bot.Controls.Add(UI.Btn("Supprimer la derni\u00E8re \u00E9tiquette \uD83D\uDDD1", delegate { DelLast(); }, false, 32));
        var hint = UI.Lab(t, "Double-cliquez sur une \u00E9tiquette pour ouvrir la fen\u00EAtre Etiquette.");
        t.Controls.Add(hint);
        hint.Dock = DockStyle.Bottom;
    }
    public void RefreshLabels()
    {
        Row L = lig != null ? S.Line(rec, lig) : null;
        List<Row> lab = lig != null ? S.Labels(rec, lig) : new List<Row>();
        var rows = new List<GRow>();
        foreach (Row e in lab)
            rows.Add(new GRow(e.S("id"), new[] { e.S("id"), e.S("st"), string.IsNullOrEmpty(e.S("emp")) ? "-" : e.S("emp"),
                U.F3(e.D("qt")), string.IsNullOrEmpty(e.S("lot")) ? "-" : e.S("lot"), e.S("cd"),
                (e.S("pc") ?? "-"), (e.S("ob") ?? "-") }, e.S("st") == "NRECEP"));
        g2.Fill(rows);
        double totq = 0;
        foreach (Row e in lab) totq += e.D("qt");
        bool ok = L != null && lab.Count > 0 && Math.Abs(totq - L.D("qt") * lab.Count) < .0005;
        an.Text = L != null ? U.F3(L.D("qt")) : "0,000";
        tot.Text = U.F3(totq);
        tot.BackColor = ok ? Color.FromArgb(0x4c, 0xb8, 0x66) : Color.Red;
        App.Refresh();
    }
    void Edit()
    {
        if (g2.Cur == null) { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette."); return; }
        Row cur = S.Label(g2.Cur);
        if (cur == null) return;
        if (cur.S("st") == "LOGIQUE" || cur.S("st") == "SORTI") { U.Warn(this, "\u00C9tiquette d\u00E9j\u00E0 qualifi\u00E9e."); return; }
        using (EtiDlg d = new EtiDlg(App, g2.Cur)) { d.ShowDialog(this); }
        RefreshLabels();
    }
    void Copy(bool add)
    {
        try { S.CopyLabels(rec, lig, g2.Cur, add); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        RefreshLabels();
    }
    void DelLast()
    {
        try { S.DelLastLabel(rec, lig); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        RefreshLabels();
    }
    void Imprimer()
    {
        if (lig == null) { U.Warn(this, "S\u00E9lectionnez une ligne."); return; }
        bool done;
        try { done = S.PreparePrint(rec, lig); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        RefreshLabels();
        if (done) new Impression(App, rec, lig).Show();
        else new VisLab(App, rec, lig).Show();
    }
}

public class VisLab : Win
{
    string rec, lig; Action afterCb; string lot;
    string tab = "v";
    Grid gl, gs;
    ComboBox ecb;
    Label c1, c3;

    public VisLab(App app, string rec, string lig) : base(app, "S\u00E9lection Visitage & Laboratoire", "660x600")
    {
        this.rec = rec; this.lig = lig;
        Body.Controls.Add(UI.Lab(null, rec + lig));
        Body.Controls.Add(UI.Lab(null, "Liste des lots de la ligne de r\u00E9ception"));
        gl = new Grid(Body, new[] { "Lot", "Chrono", "Visit.", "Labo" }, new[] { 80, 170, 90, 90 }, 3, SelLot, null, null);
        var tb = new FlowLayoutPanel { Dock = DockStyle.Top, BackColor = Color.White, Height = 34 };
        var rv = UI.Check("\u2702 Visitage"); var rl = UI.Check("\u2697 Laboratoire");
        rv.CheckedChanged += delegate { if (rv.Checked) { tab = "v"; rl.Checked = false; Refresh(); } };
        rl.CheckedChanged += delegate { if (rl.Checked) { tab = "l"; rv.Checked = false; Refresh(); } };
        rv.Checked = true;
        tb.Controls.Add(rv); tb.Controls.Add(rl);
        var box = UI.Frame("");
        box.Dock = DockStyle.Fill;
        var inner = new Panel { Dock = DockStyle.Fill, BackColor = Color.White };
        box.Controls.Add(inner);

        var r = UI.Tlp(3);
        r.Dock = DockStyle.Top;
        inner.Controls.Add(r);
        UI.Lab(r, "Etiquette s\u00E9lectionn\u00E9e");
        ecb = new ComboBox { Width = 260, DropDownStyle = ComboBoxStyle.DropDown, Font = C.FONT };
        ecb.KeyDown += delegate(object s, KeyEventArgs ev) { if (ev.KeyCode == Keys.Enter) { ev.SuppressKeyPress = true; Add(); } };
        r.Controls.Add(ecb, 1, 0);
        r.Controls.Add(UI.Btn("S\u00E9lectionner", delegate { Add(); }, false, 14), 2, 0);
        gs = new Grid(null, new[] { "Etiquette", "Longueur annonc\u00E9e" }, new[] { 260, 160 }, 4, null, null, null);
        gs.Dock = DockStyle.Top;
        inner.Controls.Add(gs);
        gs.BringToFront();
        var cn = new FlowLayoutPanel { Dock = DockStyle.Bottom, BackColor = Color.White, Height = 90 };
        box.Controls.Add(cn);
        UI.Btn("\uD83D\uDDD1", delegate { ClearSel(); }, false, 3);
        var cc = UI.Tlp(2);
        cn.Controls.Add(cc);
        c1 = new Label { Text = "0", Width = 60, BorderStyle = BorderStyle.FixedSingle, TextAlign = ContentAlignment.MiddleRight };
        var c2 = new Label { Text = "1", Width = 60, BorderStyle = BorderStyle.FixedSingle, TextAlign = ContentAlignment.MiddleRight };
        c3 = new Label { Text = "0", Width = 60, BorderStyle = BorderStyle.FixedSingle, TextAlign = ContentAlignment.MiddleRight };
        cc.Controls.Add(UI.Lab(null, "Nombre d\u2019\u00E9tiquette du lot :"), 0, 0); cc.Controls.Add(c1, 1, 0);
        cc.Controls.Add(UI.Lab(null, "Nombre d\u2019\u00E9tiquettes \u00E0 s\u00E9lectionner :"), 0, 1); cc.Controls.Add(c2, 1, 1);
        cc.Controls.Add(UI.Lab(null, "Nombre d\u2019\u00E9tiquettes s\u00E9lectionn\u00E9es :"), 0, 2); cc.Controls.Add(c3, 1, 2);
        Body.Controls.Add(box);
        Body.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Quit(); }, false, 14));
        Refresh();
    }

    public new void Refresh()
    {
        List<DictO> L = S.Lots(rec, lig);
        var rows = new List<GRow>();
        foreach (DictO z in L)
            rows.Add(new GRow(Json.S(z, "lot"), new[] { Json.S(z, "lot"), Json.S(z, "chrono"),
                ((List<string>)z["v"]).Count > 0 ? "OK" : "", ((List<string>)z["l"]).Count > 0 ? "OK" : "" }, false));
        gl.Fill(rows);
        if (lot == null && L.Count > 0) lot = Json.S(L[0], "lot");
        DictO z2 = null;
        foreach (DictO z in L) if (Json.S(z, "lot") == lot) { z2 = z; break; }
        if (z2 == null) return;
        var ids = new List<string>();
        foreach (Row e in S.Labels(rec, lig))
            if ((string.IsNullOrEmpty(e.S("lot")) ? "1" : e.S("lot")) == Json.S(z2, "lot")) ids.Add(e.S("id"));
        string cur = ecb.Text;
        ecb.Items.Clear();
        foreach (string i in ids) ecb.Items.Add(i);
        if (ecb.Items.Contains(cur)) ecb.Text = cur;
        List<string> sel = tab == "v" ? (List<string>)z2["v"] : (List<string>)z2["l"];
        Row ln = S.Line(rec, lig);
        var srows = new List<GRow>();
        foreach (string i in sel) srows.Add(new GRow(i, new[] { i, U.F3(ln.D("qt")) }, false));
        gs.Fill(srows);
        c1.Text = Convert.ToString(ids.Count);
        c3.Text = Convert.ToString(sel.Count);
        c3.BackColor = sel.Count > 0 ? Color.FromArgb(0x4c, 0xb8, 0x66) : Color.White;
    }
    void SelLot(string cur)
    {
        if (cur != null && cur != lot) { lot = cur; Refresh(); }
    }
    void Add()
    {
        bool done;
        try { done = S.SelectLabel(rec, lig, lot, tab, ecb.Text.Trim()); }
        catch (ValueError e) { U.Warn(this, e.Message); return; }
        ecb.Text = "";
        Refresh();
        if (done) U.Info(this, "Vous pouvez imprimer les \u00E9tiquettes.");
    }
    void ClearSel()
    {
        S.ClearSelection(rec, lig, lot, tab);
        Refresh();
    }
    void Quit()
    {
        bool done = S.LotsDone(rec, lig);
        Close();
        if (afterCb != null) afterCb();
        if (done) new Impression(App, rec, lig).Show();
    }
}

public class Impression : Win
{
    string rec, lig;
    public Impression(App app, string rec, string lig) : base(app, "Impression des \u00E9tiquettes de test", "800x420")
    {
        this.rec = rec; this.lig = lig;
        var g = new Grid(Body, new[] { "Chrono", "Lot", "Etiquette", "Vis", "Lab" }, new[] { 120, 60, 200, 50, 50 }, 10, null, null, null);
        g.Dock = DockStyle.Fill;
        var ch = new Dictionary<string, string>();
        foreach (DictO z in S.Lots(rec, lig)) ch[Json.S(z, "lot")] = Json.S(z, "chrono");
        var rows = new List<GRow>();
        foreach (Row e in S.Labels(rec, lig))
        {
            string lot = string.IsNullOrEmpty(e.S("lot")) ? "1" : e.S("lot");
            string chrono; ch.TryGetValue(lot, out chrono);
            rows.Add(new GRow(e.S("id"), new[] { chrono ?? "", lot, e.S("id"), "X", "X" }, false));
        }
        g.Fill(rows);
        var r = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, Dock = DockStyle.Right, Width = 240, BackColor = Color.White };
        r.Controls.Add(UI.Btn("Document Visitage \uD83D\uDCC4", delegate { Visitage(); }, false, 24));
        r.Controls.Add(UI.Btn("Piplette Zebra \uD83D\uDDA8", delegate { Piplette(); }, false, 24));
        r.Controls.Add(UI.Btn("Impression \u00E9tiquettes\nZebra r\u00E9seau \u25A5", delegate { Zebra("net"); }, false, 24));
        r.Controls.Add(UI.Btn("Impression \u00E9tiquettes\nZebra s\u00E9rie \u25A5", delegate { Zebra("serie"); }, false, 24));
        r.Controls.Add(UI.Btn("Test imprimante \u25A5", delegate { Zebra("test"); }, false, 24));
        r.Controls.Add(UI.Btn("Imprimer (navigateur) \uD83D\uDDA8", delegate { Navigateur(); }, false, 24));
        r.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 24));
    }
    List<Row> Rows() { return S.Labels(rec, lig); }

    void SendZpl(byte[] data)
    {
        if (S.Cfg("zip") != "")
            U.SendNet(data, S.Cfg("zip"), S.Cfg("zport", "9100"));
        else
            U.SendSerial(data, S.Cfg("com", "COM1"), S.Cfg("baud", "9600"), S.Cfg("bits", "8"),
                         S.Cfg("stop", "1"), S.Cfg("par", "Sans"), S.Cfg("dtr", "1"),
                         U.Num(S.Cfg("tmo", "100")) / 1000, S.Cfg("buf", "5000"));
    }
    void Piplette()
    {
        try
        {
            var sb = new System.Text.StringBuilder();
            foreach (Row e in Rows()) sb.Append(U.ZplPiplette(e, S));
            byte[] data = System.Text.Encoding.UTF8.GetBytes(sb.ToString());
            if (data.Length == 0) { U.Warn(this, "Aucune \u00E9tiquette \u00E0 imprimer."); return; }
            SendZpl(data);
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "Impression impossible : " + ex.Message + "\n\nV\u00E9rifiez le menu \u00AB Imprimante Zebra \u00BB.",
                C.APP, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        U.Info(this, "Piplette(s) envoy\u00E9e(s) \u00E0 la Zebra.");
    }
    void Zebra(string mode)
    {
        try
        {
            byte[] data;
            if (mode == "test") data = System.Text.Encoding.UTF8.GetBytes(U.ZplTest());
            else
            {
                var sb = new System.Text.StringBuilder();
                foreach (Row e in Rows()) sb.Append(U.Zpl(e));
                data = System.Text.Encoding.UTF8.GetBytes(sb.ToString());
            }
            if (mode == "test" && S.Cfg("zip") != "")
                U.SendNet(data, S.Cfg("zip"), S.Cfg("zport", "9100"));
            else if (mode == "test")
                U.SendSerial(data, S.Cfg("com", "COM1"), S.Cfg("baud", "9600"), S.Cfg("bits", "8"),
                             S.Cfg("stop", "1"), S.Cfg("par", "Sans"), S.Cfg("dtr", "1"),
                             U.Num(S.Cfg("tmo", "100")) / 1000, S.Cfg("buf", "5000"));
            else if (mode == "net") U.SendNet(data, S.Cfg("zip"), S.Cfg("zport", "9100"));
            else U.SendSerial(data, S.Cfg("com", "COM1"), S.Cfg("baud", "9600"), S.Cfg("bits", "8"),
                              S.Cfg("stop", "1"), S.Cfg("par", "Sans"), S.Cfg("dtr", "1"),
                              U.Num(S.Cfg("tmo", "100")) / 1000, S.Cfg("buf", "5000"));
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "Impossible d\u2019imprimer : " + ex.Message + "\n\nV\u00E9rifiez le menu \u00AB Imprimante Zebra \u00BB, " +
                "ou utilisez \u00AB Imprimer (navigateur) \u00BB.", C.APP, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        U.Info(this, mode == "test" ? "Test envoy\u00E9 \u00E0 la Zebra." : Rows().Count + " \u00E9tiquette(s) envoy\u00E9e(s) \u00E0 la Zebra.");
    }
    void Navigateur() { U.OpenHtml(U.LabelsHtml(S, Rows())); }
    void Visitage()
    {
        List<DictO> L = S.Lots(rec, lig);
        var sb = new System.Text.StringBuilder();
        sb.Append("<h3>Document de visitage \u2014 r\u00E9ception " + rec + " ligne " + lig + "</h3>");
        foreach (DictO z in L)
        {
            sb.Append("<p>Lot " + U.Esc(Json.S(z, "lot")) + " \u00B7 Chrono " + Json.S(z, "chrono") +
                "<br>Visitage : " + string.Join(", ", ((List<string>)z["v"]).ToArray()).Replace("", "\u2014") +
                "<br>Laboratoire : " + string.Join(", ", ((List<string>)z["l"]).ToArray()) + "</p>");
        }
        U.OpenHtml(sb.ToString());
    }
}
}

// ===== part05_consult.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Consultation / Tiers / Histo / Zebra / Commandes / Picking / Inventaire \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictS = System.Collections.Generic.IDictionary<string, string>;

// \u2500\u2500 Consultation des Stocks \u2500\u2500
public class Consult : Win
{
    public static readonly Dictionary<string, string> MAP = new Dictionary<string, string> {
        {"Tous", "Tous"}, {"R\u00E9ception", "RECEP"}, {"Logique", "LOGIQUE"},
        {"Non re\u00E7ue", "NRECEP"}, {"Sortie", "SORTI"}};

    Dictionary<string, TextBox> V;
    ComboBox tp;
    Dictionary<string, CheckBox> T;
    bool busy;
    Dictionary<string, DictO> R;
    Grid g1, g2, g3;
    Label u;

    public Consult(App app) : base(app, "Consultation des Stocks", "1100x760")
    {
        R = new Dictionary<string, DictO>();
        V = new Dictionary<string, TextBox>();
        foreach (string k in new[] { "cl", "rf", "co", "fo", "nl", "of", "en", "lc" })
        {
            TextBox e = UI.Ent(20); V[k] = e;
        }
        tp = new ComboBox(); tp.DropDownStyle = ComboBoxStyle.DropDownList; tp.Font = C.FONT;
        foreach (string k in MAP.Keys) tp.Items.Add(k);
        tp.SelectedIndex = 0;
        T = new Dictionary<string, CheckBox>();
        foreach (string k in new[] { "g", "f", "m" }) { CheckBox c = UI.Check(""); c.Checked = true; T[k] = c; }
        busy = false;

        Panel top = new Panel(); top.BackColor = Color.White; top.Dock = DockStyle.Top; top.Height = 160;

        TableLayoutPanel root = new TableLayoutPanel();
        root.Dock = DockStyle.Fill; root.BackColor = Color.White; root.ColumnCount = 1;
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        Body.Controls.Add(root);
        root.Controls.Add(top, 0, 0);

        Panel left = new Panel(); left.BackColor = Color.White; left.Dock = DockStyle.Left; left.Width = 340;
        TableLayoutPanel ltl = new TableLayoutPanel(); ltl.Dock = DockStyle.Top; ltl.Height = 26 * 4 + 4;
        ltl.BackColor = Color.White; ltl.ColumnCount = 4; ltl.RowCount = 4;
        for (int i = 0; i < 4; i++) ltl.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        left.Controls.Add(ltl);
        int row = 0;
        foreach (string[] t in new[] { new[] { "cl", "client", "Client" }, new[] { "rf", "reference", "R\u00E9f\u00E9rence" },
                                       new[] { "co", "coloris", "Coloris" }, new[] { "fo", "fournisseur", "Fournisseur" } })
        {
            new CodeField(ltl, App, t[1], t[2], V[t[0]], row, 8);
            row++;
        }

        TableLayoutPanel m = new TableLayoutPanel();
        m.Dock = DockStyle.Fill; m.BackColor = Color.White; m.ColumnCount = 2;
        string[][] mid = {
            new[] { "nl", "Num\u00E9ro L, M, X :" }, new[] { "of", "N\u00B0 OF :" },
            new[] { "en", "N\u00B0 Envoi/Transfert :" }, new[] { "lc", "N\u00B0 Lancement :" } };
        for (int i = 0; i < mid.Length; i++)
        {
            m.Controls.Add(UI.Lab(null, mid[i][1]), 0, i);
            m.Controls.Add(V[mid[i][0]], 1, i);
        }
        m.Controls.Add(UI.Lab(null, "Type Stock"), 0, 4);
        tp.Width = 140;
        m.Controls.Add(tp, 1, 4);

        Panel right = new Panel(); right.BackColor = Color.White; right.Dock = DockStyle.Right; right.Width = 200;
        GroupBox box = UI.Frame("Types"); box.Dock = DockStyle.Top; box.Height = 92;
        foreach (KeyValuePair<string, CheckBox> kv in T)
        {
            string kk = kv.Key;
            kv.Value.Text = kk == "g" ? "Galon et bande" : (kk == "f" ? "Fournitures" : "Mati\u00E8re");
            box.Controls.Add(kv.Value);
            kv.Value.Dock = DockStyle.Top; kv.Value.Height = 22;
        }
        Button go = UI.Btn("Consulter \uD83D\uDD0D", delegate { Go(); }, false, 16);
        go.Dock = DockStyle.Top; go.Top = 96;
        right.Controls.Add(go); right.Controls.Add(box);

        top.Controls.Add(left); top.Controls.Add(m); top.Controls.Add(right);

        u = UI.Lab(null, "Unit\u00E9 d\u2019utilisation :");
        var fill = new TableLayoutPanel();
        fill.Dock = DockStyle.Fill; fill.BackColor = Color.White; fill.ColumnCount = 1;
        g1 = new Grid(null, new[] { "R\u00E9f\u00E9rence", "D\u00E9signation", "Coloris", "Libell\u00E9 Coloris", "Fournisseur", "Date Maj" },
                      new[] { 140, 200, 100, 160, 130, 100 }, 6, Sync, null, null);
        g2 = new Grid(null, new[] { "R\u00E9ception", "Labo ET", "Labo FT", "Litige", "Rebut", "Stock Secondaire", "En Commande", "Dispo" },
                      new int[] { 100, 100, 100, 100, 100, 100, 100, 100 }, 6, Sync, null, new[] { 0, 1, 2, 3, 4, 5, 6, 7 });
        g3 = new Grid(null, new[] { "Logique", "Surplus Log.", "Bloqu\u00E9e", "Sp\u00E9c. Non Aff", "Sp\u00E9c. Aff", "DONT Surplus Sp\u00E9cial", "R\u00E9serv\u00E9", "R\u00E9s Simul\u00E9" },
                      new int[] { 100, 100, 100, 100, 100, 100, 100, 100 }, 6, Sync, null, new[] { 0, 1, 2, 3, 4, 5, 6, 7 });
        foreach (Grid g in new Grid[] { g1, g2, g3 }) { g.Dock = DockStyle.Top; g.Height = 6 * 20 + 26; }
        g2.t.CellMouseClick += CellClick;
        g3.t.CellMouseClick += CellClick;
        Label hint = UI.Lab(null, "Indiquez un crit\u00E8re (Client, R\u00E9f\u00E9rence, Coloris ou N\u00B0 L/M/X, OF, Envoi, Lancement) puis cliquez \u00AB Consulter \uD83D\uDD0D \u00BB.");

        int r = 0;
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.Controls.Add(u, 0, ++r);
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.Controls.Add(g1, 0, ++r);
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.Controls.Add(g2, 0, ++r);
        root.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        root.Controls.Add(g3, 0, ++r);
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.Controls.Add(hint, 0, ++r);
    }

    void Go()
    {
        var f = new Dictionary<string, string>();
        foreach (KeyValuePair<string, TextBox> kv in V) f[kv.Key] = kv.Value.Text;
        string tpv; MAP.TryGetValue((string)tp.SelectedItem, out tpv); f["tp"] = tpv ?? "Tous";
        foreach (KeyValuePair<string, CheckBox> kv in T) f[kv.Key] = kv.Value.Checked ? "1" : "";
        List<DictO> rows = S.Consult(f);
        R = new Dictionary<string, DictO>();
        foreach (DictO rr in rows)
            R[Json.S(rr, "rf") + "|" + Json.S(rr, "co") + "|" + Json.S(rr, "fo")] = rr;

        var l1 = new List<GRow>(); var l2 = new List<GRow>(); var l3 = new List<GRow>();
        foreach (KeyValuePair<string, DictO> kv in R)
        {
            DictO rr = kv.Value;
            string rf = Json.S(rr, "rf"), co = Json.S(rr, "co"), fo = Json.S(rr, "fo");
            string lib = S.Lib("reference", rf); if (lib == null || lib == "") lib = rf;
            string libc = S.Lib("coloris", co); if (libc == null || libc == "") libc = co;
            l1.Add(new GRow(kv.Key, new[] { rf, lib, co, libc, fo, Json.S(rr, "d") }, false));
            l2.Add(new GRow(kv.Key, new[] { U.F3(Json.N(rr, "rec")), U.F3(Json.N(rr, "et")), U.F3(Json.N(rr, "ft")), U.F3(0), U.F3(0),
                                            U.F3(Json.N(rr, "sec")), U.F3(0), U.F3(Json.N(rr, "log") - Json.N(rr, "res")) }, false));
            l3.Add(new GRow(kv.Key, new[] { U.F3(Json.N(rr, "log")), U.F3(Json.N(rr, "sur")), U.F3(Json.N(rr, "res")), U.F3(0), U.F3(0),
                                            U.F3(0), U.F3(Json.N(rr, "res")), U.F3(0) }, false));
        }
        g1.Fill(l1); g2.Fill(l2); g3.Fill(l3);
        u.Text = "Unit\u00E9 d\u2019utilisation : " + (rows.Count > 0 ? (Json.S(rows[0], "un") ?? "") : "");
    }

    void CellClick(object sender, DataGridViewCellMouseEventArgs e)
    {
        if (e.RowIndex < 0) return;
        DataGridView w = (DataGridView)sender;
        string iid = Convert.ToString(w.Rows[e.RowIndex].Tag);
        DataRowSel(w, iid, e.ColumnIndex);
    }

    void DataRowSel(DataGridView w, string iid, int col)
    {
        if (string.IsNullOrEmpty(iid)) return;
        DictO rr; if (!R.TryGetValue(iid, out rr)) return;
        string act = null;
        if (w == g2.t) { if (col == 1) act = "et"; else if (col == 2) act = "ft"; else if (col == 7) act = "dispo"; }
        else { if (col == 0) act = "log"; else if (col == 1) act = "sur"; else if (col == 2) act = "blo"; }
        if (act == "log") new DetStockLogique(App, rr).Show();
        else if (act == "sur") new DetSurplus(App, rr).Show();
        else if (act == "blo") new DetBloque(App, rr).Show();
        else if (act == "dispo") new DetDispo(App, rr).Show();
        else if (act == "et") new DetLabo(App, rr, "LABOET").Show();
        else if (act == "ft") new DetLabo(App, rr, "LABOFT").Show();
    }

    void Sync(string cur)
    {
        if (busy || cur == null || cur == "") return;
        busy = true;
        foreach (Grid g in new Grid[] { g1, g2, g3 })
            if (g.Cur != cur) g.SelectId(cur, false);
        busy = false;
    }
}

// \u2500\u2500 Tiers et donn\u00E9es de base \u2500\u2500
public class Tiers : Win
{
    Dictionary<string, Grid> G;
    Dictionary<string, TextBox[]> E;

    public Tiers(App app) : base(app, "Tiers et donn\u00E9es de base", "740x520")
    {
        G = new Dictionary<string, Grid>(); E = new Dictionary<string, TextBox[]>();
        var nb = new TabControl(); nb.Dock = DockStyle.Fill;
        Body.Controls.Add(nb);
        foreach (KeyValuePair<string, string> kv in C.NAMES)
        {
            string k = kv.Key;
            var page = new Panel(); page.BackColor = Color.White;
            nb.TabPages.Add(new TabPage(kv.Value)); nb.TabPages[nb.TabPages.Count - 1].Controls.Add(page);
            var tlp = new TableLayoutPanel();
            tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
            tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            page.Controls.Add(tlp);
            var g = new Grid(null, new[] { "Code", "Libell\u00E9" }, new[] { 160, 420 }, 10, null, null, null);
            g.Dock = DockStyle.Fill;
            tlp.Controls.Add(g, 0, 0);
            var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.FlowDirection = FlowDirection.LeftToRight;
            bar.BackColor = Color.White; bar.Padding = new Padding(6); bar.WrapContents = false; bar.Height = 40;
            tlp.Controls.Add(bar, 0, 1);
            var c = UI.Ent(14); var l = UI.Ent(36);
            bar.Controls.Add(c); bar.Controls.Add(l);
            bar.Controls.Add(UI.Btn("Ajouter", delegate { Add(k, c, l); }, false, 10));
            bar.Controls.Add(UI.Btn("Supprimer", delegate { Rm(k, g); }, true, 10));
            G[k] = g; E[k] = new TextBox[] { c, l };
            Fill(k);
        }
    }

    void Fill(string k)
    {
        var rows = new List<GRow>();
        foreach (Row rr in S.Tiers(k)) rows.Add(new GRow(rr.S("code"), new[] { rr.S("code"), rr.S("lib") }, false));
        G[k].Fill(rows);
    }

    void Add(string k, TextBox c, TextBox l)
    {
        try { S.AddTiers(k, c.Text, l.Text); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        c.Text = ""; l.Text = "";
        Fill(k);
    }

    void Rm(string k, Grid g)
    {
        if (g.Cur != null && g.Cur != "") { S.DelTiers(k, g.Cur); Fill(k); }
    }
}

// \u2500\u2500 Historique \u2500\u2500
public class Histo : Win
{
    public Histo(App app) : base(app, "Historique", "760x500")
    {
        var g = new Grid(null, new[] { "Date", "Action" }, new[] { 170, 540 }, 20, null, null, null);
        g.Dock = DockStyle.Fill; Body.Controls.Add(g);
        var rows = new List<GRow>();
        List<Row> h = S.Q("SELECT * FROM hist ORDER BY rowid DESC LIMIT 300");
        for (int i = 0; i < h.Count; i++)
            rows.Add(new GRow(Convert.ToString(i), new[] { h[i].S("ts"), h[i].S("msg") }, false));
        g.Fill(rows);
    }
}

// \u2500\u2500 Param\u00E9trage Zebra (r\u00E9seau + s\u00E9rie complet) \u2500\u2500
public class ZebraSet : Win
{
    Dictionary<string, TextBox> V;
    ComboBox par;
    CheckBox dtr;

    public ZebraSet(App app) : base(app, "Imprimante Zebra", "560x520")
    {
        V = new Dictionary<string, TextBox>();
        string[] netKeys = { "zip", "zport" }; string[] netDefs = { "", "9100" };
        string[] serKeys = { "com", "baud", "bits", "stop", "tmo", "buf" };
        string[] serDefs = { "COM1", "9600", "8", "1", "100", "5000" };

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var net = UI.Frame("Zebra r\u00E9seau"); net.Height = 100;
        var ntlp = new TableLayoutPanel(); ntlp.Dock = DockStyle.Fill; ntlp.BackColor = Color.White; ntlp.ColumnCount = 2;
        ntlp.Controls.Add(UI.Lab(null, "Adresse IP"), 0, 0);
        ntlp.Controls.Add(Mk("zip", netDefs[0], 22), 1, 0);
        ntlp.Controls.Add(UI.Lab(null, "Port r\u00E9seau"), 0, 1);
        ntlp.Controls.Add(Mk("zport", netDefs[1], 22), 1, 1);
        net.Controls.Add(ntlp);

        var ser = UI.Frame("Zebra s\u00E9rie (param\u00E9trage complet)"); ser.Height = 300;
        var stlp = new TableLayoutPanel(); stlp.Dock = DockStyle.Fill; stlp.BackColor = Color.White; stlp.ColumnCount = 2;
        string[][] serLab = {
            new[] { "com", "Port COM" }, new[] { "baud", "Vitesse (bauds)" }, new[] { "bits", "Bits de donn\u00E9es" },
            new[] { "stop", "Bit de stop" }, new[] { "tmo", "Dur\u00E9e attendue / fin com (ms)" },
            new[] { "buf", "Buffer entr\u00E9e / sortie (octets)" } };
        for (int i = 0; i < serLab.Length; i++)
        {
            stlp.Controls.Add(UI.Lab(null, serLab[i][1]), 0, i);
            stlp.Controls.Add(Mk(serLab[i][0], serDefs[i], 20), 1, i);
        }
        stlp.Controls.Add(UI.Lab(null, "Parit\u00E9"), 0, 6);
        par = new ComboBox(); par.DropDownStyle = ComboBoxStyle.DropDownList; par.Font = C.FONT;
        par.Items.Add("Sans"); par.Items.Add("Paire"); par.Items.Add("Impaire");
        string pv = S.Cfg("par", "Sans"); int pi = 0;
        if (pv == "Paire") pi = 1; else if (pv == "Impaire") pi = 2;
        par.SelectedIndex = pi;
        stlp.Controls.Add(par, 1, 6);
        dtr = UI.Check("Protocole DTR/DSR");
        dtr.Checked = U.Num(S.Cfg("dtr", "1")) != 0;
        stlp.Controls.Add(dtr, 1, 7);
        ser.Controls.Add(stlp);

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 44; bar.BackColor = Color.White;
        bar.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Ok(); }, false, 16));
        bar.Controls.Add(UI.Btn("Test imprimante \u25A5", delegate { Test("net"); }, false, 18));
        bar.Controls.Add(UI.Btn("Test s\u00E9rie \u25A5", delegate { Test("serie"); }, false, 16));
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        var note = new Label();
        note.Text = "\u00AB Test imprimante \u00BB utilise le r\u00E9seau si l\u2019adresse IP est renseign\u00E9e,\nsinon il utilise le port s\u00E9rie. V\u00E9rifiez le c\u00E2ble, le port COM et que\nl\u2019imprimante est allum\u00E9e (diode verte).";
        note.Font = C.FONT; note.BackColor = Color.White; note.AutoSize = true;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(net, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(ser, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(note, 0, 3);
    }

    TextBox Mk(string k, string def, int w)
    {
        TextBox e = UI.Ent(w); e.Text = S.Cfg(k, def); V[k] = e; return e;
    }

    void Ok()
    {
        foreach (KeyValuePair<string, TextBox> kv in V) S.SetCfg(kv.Key, kv.Value.Text.Trim());
        S.SetCfg("par", (string)par.SelectedItem);
        S.SetCfg("dtr", dtr.Checked ? 1 : 0);
        S.Log("Param\u00E8tres Zebra enregistr\u00E9s");
        Close();
    }

    void Test(string mode)
    {
        byte[] d = Encoding.UTF8.GetBytes(U.ZplTest());
        try
        {
            if (mode == "net")
            {
                string ip = V["zip"].Text.Trim();
                if (ip == "") { U.Warn(this, "Renseignez d\u2019abord l\u2019adresse IP pour tester le r\u00E9seau."); return; }
                U.SendNet(d, ip, V["zport"].Text.Trim() == "" ? 9100 : (object)V["zport"].Text.Trim());
            }
            else
            {
                double t = U.Num(V["tmo"].Text) / 1000.0; if (t == 0) t = 0.1;
                U.SendSerial(d, V["com"].Text.Trim(), V["baud"].Text, V["bits"].Text, V["stop"].Text,
                             (string)par.SelectedItem, dtr.Checked, t, V["buf"].Text);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "Test \u00E9chou\u00E9 : " + ex.Message, C.APP, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        U.Info(this, "Test envoy\u00E9 : une \u00E9tiquette \u00AB TEST PRO TEXTILE \u00BB\ndoit sortir de l\u2019imprimante.");
    }
}

// \u2500\u2500 Ajouter une taille \u2500\u2500
public class SizeDlg : Win
{
    Action cb;
    TextBox n, c;

    public SizeDlg(App app, Action cb) : base(app, "Ajouter une taille", "400x190")
    {
        this.cb = cb;
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        n = UI.Ent(16); c = UI.Ent(16); c.Text = "1,0";
        tlp.Controls.Add(UI.Lab(null, "Nom de la taille (ex : XXXL)"), 0, 0); tlp.Controls.Add(n, 1, 0);
        tlp.Controls.Add(UI.Lab(null, "Coefficient (taille M = 1,0)"), 0, 1); tlp.Controls.Add(c, 1, 1);
        var fr = new FlowLayoutPanel(); fr.BackColor = Color.White;
        fr.Controls.Add(UI.Btn("Ajouter \u2714", delegate { Ok(); }, false, 12));
        fr.Controls.Add(UI.Btn("Annuler \u2715", delegate { Close(); }, true, 12));
        tlp.Controls.Add(fr, 0, 2);
        tlp.SetColumnSpan(fr, 2);
        Body.Controls.Add(tlp);
    }

    void Ok()
    {
        try { S.AddSize(n.Text, c.Text); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        Close();
        if (cb != null) cb();
    }
}

// \u2500\u2500 Commandes OF \u2013 Simulation de besoin \u2500\u2500
public class Commandes : Win
{
    TextBox of;
    Dictionary<string, TextBox> q;
    TextBox nr, nc, nq;
    TableLayoutPanel szw;
    Grid gn, gr, gc;

    public Commandes(App app) : base(app, "Commandes OF \u2013 Simulation de besoin", "920x840")
    {
        q = new Dictionary<string, TextBox>();
        nr = UI.Ent(16); nc = UI.Ent(16); nq = UI.Ent(8);

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 36; top.BackColor = Color.White;
        top.Controls.Add(UI.Lab(null, "N\u00B0 d\u2019OF"));
        of = UI.Ent(16); top.Controls.Add(of);

        var box = UI.Frame("Quantit\u00E9s par taille"); box.Height = 130;
        var btlp = new TableLayoutPanel(); btlp.Dock = DockStyle.Fill; btlp.BackColor = Color.White; btlp.ColumnCount = 1;
        box.Controls.Add(btlp);
        szw = new TableLayoutPanel(); szw.Dock = DockStyle.Top; szw.Height = 54; szw.BackColor = Color.White;
        btlp.Controls.Add(szw, 0, 0);
        var szb = new FlowLayoutPanel(); szb.Dock = DockStyle.Top; szb.Height = 36; szb.BackColor = Color.White;
        szb.Controls.Add(UI.Btn("Ajouter taille \u2795", delegate { AddSize(); }, false, 18));
        szb.Controls.Add(UI.Btn("Retirer la derni\u00E8re taille \u2716", delegate { RmSize(); }, true, 26));
        btlp.Controls.Add(szb, 0, 1);

        var nb = UI.Frame("Consommation par pi\u00E8ce (taille M)"); nb.Height = 185;
        var ntlp = new TableLayoutPanel(); ntlp.Dock = DockStyle.Fill; ntlp.BackColor = Color.White; ntlp.ColumnCount = 1;
        nb.Controls.Add(ntlp);
        gn = new Grid(null, new[] { "R\u00E9f\u00E9rence (1)", "Coloris (2)", "Consommation par pi\u00E8ce (3)" },
                      new[] { 200, 150, 180 }, 4, null, null, new[] { 2 });
        ntlp.Controls.Add(gn, 0, 0);
        var bar = new TableLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 80; bar.BackColor = Color.White;
        bar.ColumnCount = 4;
        for (int i = 0; i < 4; i++) bar.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        new CodeField(bar, App, "reference", "R\u00E9f\u00E9rence (1)", nr, 0, 16);
        new CodeField(bar, App, "coloris", "Coloris (2)", nc, 1, 16);
        var b3 = new FlowLayoutPanel(); b3.BackColor = Color.White; b3.WrapContents = false;
        b3.Controls.Add(UI.Lab(null, "Consommation par pi\u00E8ce (3), en m\u00E8tres :"));
        b3.Controls.Add(nq);
        b3.Controls.Add(UI.Btn("Ajouter", delegate { AddNom(); }, false, 10));
        b3.Controls.Add(UI.Btn("Retirer", delegate { DelNom(); }, true, 10));
        bar.Controls.Add(b3, 0, 2);
        bar.SetColumnSpan(b3, 4);
        ntlp.Controls.Add(bar, 0, 1);

        var act = new FlowLayoutPanel(); act.Dock = DockStyle.Top; act.Height = 38; act.BackColor = Color.White;
        act.Controls.Add(UI.Btn("Calculer le besoin \uD83D\uDD0D", delegate { Calc(); }, false, 22));
        act.Controls.Add(UI.Btn("Cr\u00E9er la commande \u2714", delegate { Create(); }, false, 22));

        gr = new Grid(null, new[] { "R\u00E9f\u00E9rence", "Coloris", "Besoin", "Disponible", "\u00C9cart", "\u00C9tat" },
                      new[] { 160, 120, 100, 100, 100, 90 }, 5, null, null, new[] { 2, 3, 4 });
        var labCmd = UI.Lab(null, "Commandes");
        gc = new Grid(null, new[] { "OF", "Pi\u00E8ces", "Statut" }, new[] { 200, 100, 140 }, 6, null, null, null);
        gc.Dock = DockStyle.Fill;
        var del = UI.Btn("Supprimer la commande", delegate { DelCmd(); }, true, 24);

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(box, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(nb, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(act, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(gr, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labCmd, 0, 5);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(gc, 0, 6);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); del.Margin = new Padding(3); tlp.Controls.Add(del, 0, 7);

        BuildSizes();
        Fill();
    }

    void BuildSizes()
    {
        szw.Controls.Clear(); szw.ColumnStyles.Clear();
        szw.ColumnCount = 2; szw.RowCount = 2;
        var szs = S.Sizes();
        szw.ColumnCount = szs.Count;
        for (int i = 0; i < szs.Count; i++) szw.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        for (int i = 0; i < szs.Count; i++)
        {
            Sz s = szs[i];
            szw.Controls.Add(UI.Lab(null, s.T + " (coef " + s.C.ToString("0.###") + ")"), i, 0);
            TextBox t;
            if (!q.TryGetValue(s.T, out t)) { t = UI.Ent(7); t.Text = "0"; q[s.T] = t; }
            if (t.Parent != null) t.Parent.Controls.Remove(t);
            szw.Controls.Add(t, i, 1);
        }
    }

    void AddSize() { new SizeDlg(App, delegate { BuildSizes(); }).ShowDialog(this); }

    void RmSize()
    {
        var L = S.Sizes();
        if (L.Count <= 1) { U.Warn(this, "Impossible de retirer la derni\u00E8re taille."); return; }
        if (!U.Ask(this, "Retirer la taille " + L[L.Count - 1].T + " de la liste ?")) return;
        S.DelSize(L[L.Count - 1].T);
        q.Remove(L[L.Count - 1].T);
        BuildSizes();
    }

    void Fill()
    {
        var r1 = new List<GRow>();
        foreach (Row n in S.Nom())
            r1.Add(new GRow(n.S("rf") + "|" + n.S("co"), new[] { n.S("rf"), n.S("co"), U.F3(n.D("c")) }, false));
        gn.Fill(r1);
        var r2 = new List<GRow>();
        foreach (Row c in S.Cmds())
            r2.Add(new GRow(c.S("n"), new[] { c.S("n"), c.S("pcs"), c.S("st") }, false));
        gc.Fill(r2);
    }

    Dictionary<string, double> Qty()
    {
        var r = new Dictionary<string, double>();
        foreach (KeyValuePair<string, TextBox> kv in q)
            r[kv.Key] = Math.Max(0, (long)U.Num(kv.Value.Text));
        return r;
    }

    void AddNom()
    {
        try { S.AddNom(nr.Text, nc.Text, nq.Text); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        nr.Text = ""; nc.Text = ""; nq.Text = "";
        Fill();
    }

    void DelNom()
    {
        if (gn.Cur == null || gn.Cur == "") return;
        int p = gn.Cur.IndexOf('|');
        if (p >= 0) { S.DelNom(gn.Cur.Substring(0, p), gn.Cur.Substring(p + 1)); Fill(); }
    }

    void Calc()
    {
        NeedResult res = S.Need(Qty());
        if (res.Pcs == 0) { U.Warn(this, "Saisissez au moins une quantit\u00E9."); return; }
        var outp = new List<GRow>();
        for (int i = 0; i < res.Rows.Count; i++)
        {
            Row rr = res.Rows[i];
            double av = S.Logique(rr.S("rf"), rr.S("co")) - S.Reserved(rr.S("rf"), rr.S("co"));
            double e = av - rr.D("q");
            outp.Add(new GRow(Convert.ToString(i), new[] { rr.S("rf"), rr.S("co"), U.F3(rr.D("q")), U.F3(av), U.F3(e),
                                                           e >= -0.0005 ? "OK" : "MANQUE" }, false));
        }
        gr.Fill(outp);
    }

    void Create()
    {
        try { S.CreateCmd(of.Text, Qty()); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        U.Info(this, "Commande cr\u00E9\u00E9e. Elle appara\u00EEt dans le Picking.");
        Fill();
    }

    void DelCmd()
    {
        if (gc.Cur == null || gc.Cur == "") { U.Warn(this, "S\u00E9lectionnez une commande."); return; }
        try { S.DelCmd(gc.Cur); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        Fill();
    }
}

// \u2500\u2500 Picking \u2013 Sortie mati\u00E8re \u2500\u2500
public class Picking : Win
{
    string[] cur;
    TextBox se, sl;
    Grid g, gs;

    public Picking(App app) : base(app, "Picking \u2013 Sortie mati\u00E8re", "900x660")
    {
        se = UI.Ent(14); sl = UI.Ent(24);
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        g = new Grid(null, new[] { "OF", "Article", "Besoin", "Sorti", "Reste" },
                     new[] { 140, 260, 100, 100, 100 }, 8, Sel, null, new[] { 2, 3, 4 });
        var hint = UI.Lab(null, "S\u00E9lectionnez une ligne \u00E0 servir. \u00C9tiquettes sugg\u00E9r\u00E9es, les plus anciennes d\u2019abord :");
        gs = new Grid(null, new[] { "Etiquette", "Emplacement", "Quantit\u00E9" }, new[] { 260, 160, 120 }, 5, null, null, new[] { 2 });
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 40; bar.BackColor = Color.White;
        bar.Controls.Add(UI.Lab(null, "Emplacement"));
        bar.Controls.Add(se);
        bar.Controls.Add(UI.Lab(null, "Etiquette"));
        bar.Controls.Add(sl);
        bar.Controls.Add(UI.Btn("Choisir", delegate { Choose(); }, false, 10));
        bar.Controls.Add(UI.Btn("Valider la sortie \u2714", delegate { Out(); }, false, 20));

        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(hint, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(gs, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);

        Fill();
    }

    void Fill()
    {
        var rows = new List<GRow>();
        foreach (Row p in S.Picks())
            rows.Add(new GRow(p.S("n") + "|" + p.S("rf") + "|" + p.S("co"),
                              new[] { p.S("n"), p.S("rf") + " " + p.S("co"), U.F3(p.D("q")), U.F3(p.D("p")),
                                      U.F3(p.D("q") - p.D("p")) }, false));
        g.Fill(rows);
        Sel(g.Cur);
    }

    void Sel(string c)
    {
        cur = string.IsNullOrEmpty(c) ? null : c.Split('|');
        var rows = new List<GRow>();
        if (cur != null)
            foreach (Row e in S.Suggest(cur[1], cur[2]))
                rows.Add(new GRow(e.S("id"), new[] { e.S("id"), e.S("emp"), U.F3(e.D("qt")) }, false));
        gs.Fill(rows);
    }

    void Choose()
    {
        if (gs.Cur != null && gs.Cur != "")
        {
            sl.Text = gs.Cur;
            Row e = S.Label(gs.Cur);
            if (e != null) se.Text = e.S("emp");
        }
    }

    void Out()
    {
        if (cur == null) { U.Warn(this, "S\u00E9lectionnez d\u2019abord une ligne \u00E0 servir."); return; }
        double q;
        try { q = S.PickOut(cur[0], cur[1], cur[2], sl.Text.Trim(), se.Text); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        sl.Text = ""; se.Text = "";
        Fill();
        U.Info(this, "Sortie valid\u00E9e : " + U.F3(q));
    }
}

// \u2500\u2500 Inventaire \u2500\u2500
public class Inventaire : Win
{
    Dictionary<string, string> cnt;
    TextBox v;
    Grid g;

    public Inventaire(App app) : base(app, "Inventaire", "900x620")
    {
        cnt = new Dictionary<string, string>();
        v = UI.Ent(12);
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        g = new Grid(null, new[] { "Emplacement", "Etiquette", "Article", "Th\u00E9orique", "Compt\u00E9" },
                     new[] { 130, 200, 240, 110, 110 }, 14, null, null, new[] { 3, 4 });
        g.Dock = DockStyle.Fill;
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 40; bar.BackColor = Color.White;
        bar.Controls.Add(UI.Lab(null, "Quantit\u00E9 compt\u00E9e"));
        bar.Controls.Add(v);
        bar.Controls.Add(UI.Btn("Enregistrer le comptage", delegate { Count(); }, false, 22));
        bar.Controls.Add(UI.Btn("Appliquer les \u00E9carts \u2714", delegate { Apply(); }, false, 22));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 1);
        Fill();
    }

    void Fill()
    {
        var rows = new List<GRow>();
        foreach (Row e in S.Inventory())
        {
            string counted;
            if (cnt.TryGetValue(e.S("id"), out counted) && counted != null && counted != "")
                counted = U.F3(U.Num(counted));
            else counted = "";
            rows.Add(new GRow(e.S("id"), new[] { e.S("emp"), e.S("id"), e.S("rf") + " " + e.S("co"),
                                                 U.F3(e.D("qt")), counted }, false));
        }
        g.Fill(rows);
    }

    void Count()
    {
        if (g.Cur == null || g.Cur == "") { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette."); return; }
        cnt[g.Cur] = v.Text.Trim();
        v.Text = "";
        Fill();
    }

    void Apply()
    {
        var counts = new Dictionary<string, string>();
        foreach (KeyValuePair<string, string> kv in cnt) if (kv.Value != null && kv.Value != "") counts[kv.Key] = kv.Value;
        int k = S.ApplyCount(counts);
        cnt = new Dictionary<string, string>();
        Fill();
        U.Info(this, k + " \u00E9cart(s) ajust\u00E9(s).");
    }
}
}

// ===== part06_det.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 D\u00E9tails stocks (Logique / Surplus / Bloqu\u00E9 / Dispo / Labo), PoidsDlg, RetourLabo \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictS2 = System.Collections.Generic.Dictionary<string, string>;

// \u2500\u2500 Fen\u00EAtre n\u00B01 : D\u00E9tails du Stock Logique \u2500\u2500
public class DetStockLogique : Win
{
    DictO r;
    TextBox rf, co;
    ComboBox tp;
    Grid g, gl;
    Label tot, nbe;

    public DetStockLogique(App app, DictO rr) : base(app, "D\u00E9tails du Stock Logique", "1000x580")
    {
        r = rr;
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 9;
        for (int i = 0; i < 9; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        rf = UI.Ent(14); rf.Text = Json.S(r, "rf");
        co = UI.Ent(10); co.Text = Json.S(r, "co");
        tp = UI.Combo("Tous");
        tp.Width = 110;
        top.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence"), 0, 0);
        top.Controls.Add(rf, 1, 0);
        top.Controls.Add(UI.Lab(null, "Couleur"), 2, 0);
        top.Controls.Add(co, 3, 0);
        top.Controls.Add(UI.Lab(null, "Type Stock"), 4, 0);
        top.Controls.Add(tp, 5, 0);
        top.Controls.Add(UI.Lab(null, "Fournisseur : " + (Json.S(r, "fo") ?? "-")), 6, 0);
        var quit = UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12);
        top.Controls.Add(quit, 8, 0);

        var labList = UI.Lab(null, "Liste des \u00E9tiquettes");
        g = new Grid(null, new[] { "Liste des \u00E9tiquettes", "F\u00E9d\u00E9ration", "Lg/Longueur", "Lot", "Laize", "Emplacement", "Th\u00E8me" },
                     new[] { 170, 120, 100, 90, 80, 110, 120 }, 10, null, null, new[] { 2 });
        g.Dock = DockStyle.Fill;

        var bot = new TableLayoutPanel(); bot.Dock = DockStyle.Top; bot.Height = 34; bot.BackColor = Color.White;
        bot.ColumnCount = 3;
        for (int i = 0; i < 3; i++) bot.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        tot = UI.InfoLbl("Total : 0,000");
        nbe = UI.InfoLbl("Nb \u00E9l\u00E9m. : 0");
        bot.Controls.Add(tot, 0, 0);
        bot.Controls.Add(nbe, 1, 0);

        var labLots = UI.Lab(null, "Liste des Lots");
        gl = new Grid(null, new[] { "Lot", "Qt\u00E9" }, new[] { 160, 120 }, 4, null, null, new[] { 1 });

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labList, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bot, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labLots, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(gl, 0, 5);

        Refresh();
    }

    List<Row> Rows()
    {
        return S.Q("SELECT * FROM eti WHERE st='LOGIQUE' AND rf=? AND co=? ORDER BY emp, id",
                   rf.Text.Trim().ToUpper(), co.Text.Trim().ToUpper());
    }

    void Refresh()
    {
        List<Row> rows = Rows();
        var l = new List<GRow>(); double sum = 0;
        foreach (Row e in rows)
        {
            sum += e.D("qt");
            l.Add(new GRow(e.S("id"), new[] { e.S("id"), e.S("fo") ?? "-", U.F3(e.D("qt")), e.S("lot") ?? "1",
                                              U.F3(S.Laize(e)), e.S("emp") ?? "-",
                                              S.Lib("client", e.S("dn")) ?? e.S("dn") }, false));
        }
        g.Fill(l);
        tot.Text = "Total : " + U.F3(sum);
        nbe.Text = "Nb \u00E9l\u00E9m. : " + rows.Count;
        var lots = new SortedDictionary<string, double>();
        foreach (Row e in rows)
        {
            string lot = e.S("lot") ?? "1";
            double qq; lots.TryGetValue(lot, out qq);
            lots[lot] = qq + e.D("qt");
        }
        var ll = new List<GRow>(); int i = 0;
        foreach (KeyValuePair<string, double> kv in lots)
        {
            ll.Add(new GRow(Convert.ToString(i), new[] { kv.Key, U.F3(kv.Value) }, false));
            i++;
        }
        gl.Fill(ll);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B02 : D\u00E9tails du surplus logique \u2500\u2500
public class DetSurplus : Win
{
    DictO r;
    Grid g, ge;
    Label title2;

    public DetSurplus(App app, DictO rr) : base(app, "D\u00E9tails du surplus logique", "1000x560")
    {
        r = rr;
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 7;
        for (int i = 0; i < 7; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        top.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence"), 0, 0);
        var rf = UI.Ent(14); rf.Text = Json.S(r, "rf"); top.Controls.Add(rf, 1, 0);
        top.Controls.Add(UI.Lab(null, "Coloris"), 2, 0);
        var co = UI.Ent(10); co.Text = Json.S(r, "co"); top.Controls.Add(co, 3, 0);
        top.Controls.Add(UI.Lab(null, "Type Stock"), 4, 0);
        top.Controls.Add(UI.Combo("Tous"), 5, 0);
        top.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12), 6, 0);

        var labOf = UI.Lab(null, "Liste des OFs");
        g = new Grid(null, new[] { "N\u00B0 L", "N\u00B0 OF", "Quantit\u00E9 \u00E0 sortir", "Quantit\u00E9 sortie", "Surplus", "Atelier" },
                     new[] { 120, 170, 130, 130, 110, 140 }, 8, PickOf, null, new[] { 2, 3, 4 });
        g.Dock = DockStyle.Fill;
        title2 = UI.Lab(null, "Liste des \u00E9tiquettes pour la sortie");
        ge = new Grid(null, new[] { "Date", "Etiquette", "Qt\u00E9 Mvrt.", "Laize" }, new[] { 170, 190, 110, 90 }, 6, null, null, new[] { 2, 3 });
        ge.Dock = DockStyle.Fill;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labOf, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(title2, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(ge, 0, 4);

        Refresh();
    }

    void Refresh()
    {
        List<Row> L = S.Q("SELECT l.*, c.st FROM cmdl l JOIN cmd c ON c.n=l.n WHERE l.rf=? AND l.co=? AND l.p > l.q ORDER BY l.n",
                          Json.S(r, "rf"), Json.S(r, "co"));
        var rows = new List<GRow>();
        foreach (Row l in L)
        {
            DictO o = S.OfdGet(l.S("n"));
            string lan; if (o != null && o.ContainsKey("lancement")) lan = Json.S(o, "lancement"); else lan = l.S("n");
            string at = o != null && o.ContainsKey("atelier") ? Json.S(o, "atelier") : "";
            rows.Add(new GRow(l.S("n"), new[] { lan, l.S("n"), U.F3(l.D("q")), U.F3(l.D("p")),
                                               U.F3(l.D("p") - l.D("q")), at }, false));
        }
        g.Fill(rows);
        PickOf(null);
    }

    void PickOf(string cur)
    {
        List<DictO> m = (cur != null && cur != "")
            ? S.Moves(Json.S(r, "rf"), Json.S(r, "co"), cur)
            : S.Moves(Json.S(r, "rf"), Json.S(r, "co"));
        title2.Text = "Liste des \u00E9tiquettes pour la sortie : " + ((cur != null && cur != "") ? cur : "tous OFs");
        var rows = new List<GRow>();
        for (int i = 0; i < m.Count; i++)
            rows.Add(new GRow(Convert.ToString(i), new[] { Json.S(m[i], "ts"), Json.S(m[i], "eid"),
                                                           U.F3(Json.N(m[i], "qt")), U.F3(Json.N(m[i], "lz")) }, false));
        ge.Fill(rows);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B03 : D\u00E9tails du Stock Bloqu\u00E9 \u2500\u2500
public class DetBloque : Win
{
    DictO r;
    Grid g, ge;
    Label qt;

    public DetBloque(App app, DictO rr) : base(app, "D\u00E9tails du Stock Bloqu\u00E9", "1100x620")
    {
        r = rr;
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 7;
        for (int i = 0; i < 7; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        top.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence"), 0, 0);
        var rf = UI.Ent(14); rf.Text = Json.S(r, "rf"); top.Controls.Add(rf, 1, 0);
        top.Controls.Add(UI.Lab(null, "Coloris"), 2, 0);
        var co = UI.Ent(10); co.Text = Json.S(r, "co"); top.Controls.Add(co, 3, 0);
        top.Controls.Add(UI.Lab(null, "Type Stock"), 4, 0);
        top.Controls.Add(UI.Combo("Tous"), 5, 0);
        top.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12), 6, 0);

        var lab1 = UI.Lab(null, "N\u00B0 de L/LT");
        g = new Grid(null, new[] { "N\u00B0 L/L", "OFs", "Date", "Besoin", "Logique Initiale", "Sortie Log.", "Restant bloqu\u00E9" },
                     new[] { 120, 150, 100, 100, 120, 110, 130 }, 8, null, null, new[] { 3, 4, 5, 6 });
        g.Dock = DockStyle.Fill;
        qt = UI.Lab(null, "Qt\u00E9 restant bloqu\u00E9e : 0,000");
        qt.Dock = DockStyle.Top; qt.TextAlign = ContentAlignment.MiddleRight;
        var lab2 = UI.Lab(null, "N\u00B0 d'Envoi ou Transfert de Stock");
        ge = new Grid(null, new[] { "Tiers", "Envoi", "Qt\u00E9 Ini. Blo.", "Qt\u00E9 Rest. Blo.", "Qt\u00E9 Sortie",
                                    "Ordre Fabrication", "Code atelier", "Atelier" },
                      new[] { 150, 140, 110, 120, 100, 150, 110, 120 }, 5, null, null, new[] { 2, 3, 4 });
        ge.Dock = DockStyle.Fill;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(qt, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab2, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(ge, 0, 5);

        Refresh();
    }

    void Refresh()
    {
        List<Row> L = S.Q("SELECT l.*, c.d FROM cmdl l JOIN cmd c ON c.n=l.n WHERE l.rf=? AND l.co=? AND c.st<>'TRAIT\u00C9' ORDER BY l.n",
                          Json.S(r, "rf"), Json.S(r, "co"));
        var rows = new List<GRow>(); double tot = 0;
        foreach (Row l in L)
        {
            double rest = Math.Max(0, l.D("q") - l.D("p"));
            tot += rest;
            DictO o = S.OfdGet(l.S("n"));
            string lan; if (o != null && o.ContainsKey("lancement")) lan = Json.S(o, "lancement"); else lan = l.S("n");
            rows.Add(new GRow(l.S("n"), new[] { lan, l.S("n"), l.S("d"), U.F3(l.D("q")), U.F3(l.D("q")),
                                               U.F3(l.D("p")), U.F3(rest) }, false));
        }
        g.Fill(rows);
        qt.Text = "Qt\u00E9 restant bloqu\u00E9e : " + U.F3(tot);
        ge.Fill(new List<GRow>());
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B04 : D\u00E9tails du Stock Dispo \u2500\u2500
public class DetDispo : Win
{
    public DetDispo(App app, DictO r) : base(app, "D\u00E9tails du Stock Dispo", "560x460")
    {
        string rf = Json.S(r, "rf"), co = Json.S(r, "co");
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence"));
        var rfT = UI.Ent(14); rfT.Text = rf; top.Controls.Add(rfT);
        top.Controls.Add(UI.Lab(null, "Couleur"));
        var coT = UI.Ent(10); coT.Text = co; top.Controls.Add(coT);

        double log = S.Logique(rf, co);
        double sur = S.Surplus(rf, co);
        double res = S.Reserved(rf, co);
        object[][] rows = {
            new object[] { "LOGIQUE", log }, new object[] { "SURPLUS LOGIQUE", sur }, new object[] { "SPECN", 0.0 },
            new object[] { "SURPLUS SPECIAL", 0.0 }, new object[] { "BLOQUE", -res }, new object[] { "RESERVE", res },
            new object[] { "RESERVE SIM.", 0.0 } };

        var lab1 = UI.Lab(null, "D\u00E9tail");
        var g = new Grid(null, new[] { "Stock", "Qt\u00E9/Longueur" }, new[] { 220, 160 }, 7, null, null, new[] { 1 });
        g.Dock = DockStyle.Fill;
        var l = new List<GRow>();
        for (int i = 0; i < rows.Length; i++)
            l.Add(new GRow(Convert.ToString(i), new[] { rows[i][0].ToString(), U.F3((double)rows[i][1]) }, false));
        g.Fill(l);

        var bot = new FlowLayoutPanel(); bot.Dock = DockStyle.Top; bot.Height = 36; bot.BackColor = Color.White;
        bot.Controls.Add(UI.Lab(null, "Total"));
        double sum = 0;
        foreach (var rr in rows) sum += (double)rr[1];
        bot.Controls.Add(UI.InfoLbl(U.F3(sum)));
        bot.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12));

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bot, 0, 3);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B06 : D\u00E9tails Labo ET / Labo FT \u2500\u2500
public class DetLabo : Win
{
    string ty;
    DictO r;
    Grid g;
    Label tot;

    public DetLabo(App app, DictO rr, string ty) : base(app, ty == "LABOET" ? "D\u00E9tails Labo ET" : "D\u00E9tails Labo FT", "1100x540")
    {
        this.ty = ty; r = rr;
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence"));
        var rf = UI.Ent(14); rf.Text = Json.S(r, "rf"); top.Controls.Add(rf);
        top.Controls.Add(UI.Lab(null, "Coloris"));
        var co = UI.Ent(10); co.Text = Json.S(r, "co"); top.Controls.Add(co);
        top.Controls.Add(UI.Lab(null, "Type Stock"));
        top.Controls.Add(UI.Combo("Tous"));
        top.Controls.Add(UI.Btn("Imprimer \uD83D\uDDA8", delegate { Imprimer(); }, false, 14));
        top.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12));

        var labList = UI.Lab(null, "Liste des Etiquettes");
        g = new Grid(null, new[] { "Etiquettes", "F\u00E9d\u00E9ration", "Empl.", "Qt\u00E9/Longueur", "Largeur", "Fournisseur",
                                   "Lot", "Observation", "N\u00B0 Chrono/Litage", "Commande" },
                     new[] { 170, 110, 100, 110, 90, 110, 90, 150, 150, 110 }, 10, null, null, new[] { 3 });
        g.Dock = DockStyle.Fill;
        tot = UI.Lab(null, "Total : 0,000");
        tot.Dock = DockStyle.Top; tot.TextAlign = ContentAlignment.MiddleRight;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labList, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(tot, 0, 3);

        Refresh();
    }

    List<Row> Rows()
    {
        return S.Q("SELECT * FROM eti WHERE st=? AND rf=? AND co=? ORDER BY emp, id",
                   ty, Json.S(r, "rf"), Json.S(r, "co"));
    }

    void Refresh()
    {
        List<Row> rows = Rows();
        var l = new List<GRow>(); double sum = 0;
        foreach (Row e in rows)
        {
            sum += e.D("qt");
            l.Add(new GRow(e.S("id"), new[] { e.S("id"), e.S("fo") ?? "-", e.S("emp") ?? "-", U.F3(e.D("qt")),
                                              U.F3(S.Laize(e)), e.S("fo") ?? "-", e.S("lot") ?? "1", e.S("ob") ?? "-",
                                              S.ChronoOf(e), e.S("cd") ?? "-" }, false));
        }
        g.Fill(l);
        tot.Text = "Total : " + U.F3(sum);
    }

    void Imprimer()
    {
        U.OpenHtml(U.LabelsHtml(S, Rows()));
    }
}

// \u2500\u2500 Sous-fen\u00EAtre \u00AB Poids / Foids \u00BB du Retour Laboratoire \u2500\u2500
public class PoidsDlg : Win
{
    string eid;
    TextBox emp, ech;

    public PoidsDlg(App app, string eid) : base(app, "Foids", "420x200")
    {
        this.eid = eid;
        Row e = S.Label(eid);
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        emp = UI.Ent(24); emp.Text = e != null ? (e.S("emp") ?? "") : "";
        ech = UI.Ent(24);
        tlp.Controls.Add(UI.Lab(null, "Etiquette"), 0, 0);
        tlp.Controls.Add(UI.InfoLbl(eid), 1, 0);
        tlp.Controls.Add(UI.Lab(null, "Emplacement"), 0, 1); tlp.Controls.Add(emp, 1, 1);
        tlp.Controls.Add(UI.Lab(null, "Echantillon Labo"), 0, 2); tlp.Controls.Add(ech, 1, 2);
        var fr = new FlowLayoutPanel(); fr.BackColor = Color.White;
        fr.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Ok(); }, false, 14));
        fr.Controls.Add(UI.Btn("Annuler \u2715", delegate { Close(); }, true, 12));
        tlp.Controls.Add(fr, 0, 3);
        tlp.SetColumnSpan(fr, 2);
        Body.Controls.Add(tlp);
    }

    void Ok()
    {
        Row e = S.Label(eid);
        string ob = e != null ? (e.S("ob") ?? "") : "";
        if (ech.Text.Trim() != "") ob = "Echantillon Labo " + ech.Text.Trim();
        S.X("UPDATE eti SET emp=?, ob=? WHERE id=?", emp.Text.Trim().ToUpper(), ob, eid);
        Close();
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B07 : Retour Laboratoire \u2500\u2500
public class RetourLabo : Win
{
    TextBox eRec, eBc;
    TabControl nb;
    Grid g1, g2, g3;
    Dictionary<Control, Grid> tabGrid;

    public RetourLabo(App app) : base(app, "Retour Laboratoire", "1020x620")
    {
        eRec = UI.Ent(16); eBc = UI.Ent(24);

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 8;
        for (int i = 0; i < 8; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        top.Controls.Add(UI.Lab(null, "Ligne de R\u00E9ception :"), 0, 0);
        top.Controls.Add(eRec, 1, 0);
        top.Controls.Add(UI.Lab(null, "Num\u00E9ro F\u00E9d\u00E9ration :"), 2, 0);
        top.Controls.Add(eBc, 3, 0);
        eBc.KeyDown += delegate(object s, KeyEventArgs ev) { if (ev.KeyCode == Keys.Enter) Afficher(); };
        top.Controls.Add(UI.Btn("Afficher \uD83D\uDD0D", delegate { Afficher(); }, false, 14), 4, 0);
        var act = new FlowLayoutPanel(); act.BackColor = Color.White;
        act.Controls.Add(UI.Btn("Recopier Emplacement \u29C9", delegate { CpyEmp(); }, false, 20));
        act.Controls.Add(UI.Btn("Recopier Laize \u29C9", delegate { CpyLaize(); }, false, 18));
        top.Controls.Add(act, 6, 0);

        nb = new TabControl(); nb.Dock = DockStyle.Fill;
        tabGrid = new Dictionary<Control, Grid>();
        string[] cols = { "N\u00B0 Etiquette", "Etat", "Lot", "Commande", "Empl.", "Lge-Util.", "Laize Util." };
        int[] w = { 170, 80, 90, 100, 110, 100, 100 };
        g1 = new Grid(null, cols, w, 10, null, Poids, new[] { 5, 6 });
        g2 = new Grid(null, cols, w, 10, null, Poids, new[] { 5, 6 });
        g3 = new Grid(null, cols, w, 10, null, Poids, new[] { 5, 6 });
        string[] tabs = { "Ligne de r\u00E9ception", "Etiquettes en Retour Labo", "Autres \u00E9tiquettes" };
        Grid[] grids = { g1, g2, g3 };
        for (int i = 0; i < 3; i++)
        {
            var page = new Panel(); page.BackColor = Color.White; page.Dock = DockStyle.Fill;
            grids[i].Dock = DockStyle.Fill;
            page.Controls.Add(grids[i]);
            TabPage tp = new TabPage(tabs[i]); tp.Controls.Add(page);
            nb.TabPages.Add(tp);
            tabGrid[page] = grids[i];
        }

        var bot = new FlowLayoutPanel(); bot.Dock = DockStyle.Top; bot.Height = 40; bot.BackColor = Color.White; bot.WrapContents = false;
        bot.Controls.Add(UI.Btn("Imprimer toutes les \u00E9tiquettes \u25A5", delegate { ImprRows(Rows(CurGrid())); }, false, 30));
        bot.Controls.Add(UI.Btn("Imprimer l\u2019\u00E9tiquette en cours \u25A5", delegate { ImprOne(); }, false, 30));
        bot.Controls.Add(UI.Btn("\u2192 Labo ET", delegate { ToLabo("LABOET"); }, false, 12));
        bot.Controls.Add(UI.Btn("\u2192 Labo FT", delegate { ToLabo("LABOFT"); }, false, 12));
        bot.Controls.Add(UI.Btn("Passage en stock Logique \u2714", delegate { ToLogique(); }, false, 26));
        bot.Controls.Add(UI.Btn("Poids \u2696", delegate { Poids(); }, false, 10));
        bot.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12));

        var help = new Label();
        help.Text = "Double-cliquez sur une \u00E9tiquette pour saisir le poids / \u00E9chantillon labo.\n\u00AB Passage en stock Logique \u00BB remet l\u2019\u00E9tiquette au labo (LABOET/LABOFT) dans le stock logique.";
        help.Font = C.FONT; help.BackColor = Color.White; help.AutoSize = true;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(nb, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bot, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(help, 0, 3);

        Refresh();
    }

    Grid CurGrid()
    {
        var page = nb.SelectedTab.Controls.Count > 0 ? nb.SelectedTab.Controls[0] : null;
        Grid g;
        if (page != null && tabGrid.TryGetValue(page, out g)) return g;
        return g1;
    }

    List<Row> Rows(Grid g)
    {
        string rec = eRec.Text.Trim();
        if (g == g1)
            return rec != "" ? S.Q("SELECT * FROM eti WHERE rec LIKE ? ORDER BY id", rec + "%") : new List<Row>();
        if (g == g2)
            return S.Q("SELECT * FROM eti WHERE st IN ('LABOET','LABOFT') ORDER BY id");
        return rec != ""
            ? S.Q("SELECT * FROM eti WHERE rec LIKE ? AND st NOT IN ('LABOET','LABOFT') ORDER BY id", rec + "%")
            : new List<Row>();
    }

    void Refresh()
    {
        Grid[] grids = { g1, g2, g3 };
        foreach (Grid g in grids)
        {
            var rows = new List<GRow>();
            foreach (Row e in Rows(g))
                rows.Add(new GRow(e.S("id"), new[] { e.S("id"), e.S("st"), e.S("lot") ?? "1", e.S("cd") ?? "-",
                                                     e.S("emp") ?? "-", U.F3(e.D("qt")), U.F3(S.Laize(e)) },
                                   e.S("st") == "NRECEP"));
            g.Fill(rows);
        }
    }

    void Afficher()
    {
        string bc = eBc.Text.Trim();
        if (bc == "") { U.Warn(this, "Saisissez le num\u00E9ro de code-barres de l\u2019\u00E9tiquette."); return; }
        Row e = S.Label(bc);
        if (e == null)
        {
            var r = S.Q("SELECT id FROM eti WHERE id LIKE ?", bc + "%");
            if (r.Count == 0) { U.Warn(this, "\u00C9tiquette introuvable."); return; }
            e = S.Label(r[0].S("id"));
        }
        eRec.Text = e.S("rec");
        eBc.Text = e.S("id");
        nb.SelectedIndex = 0;
        Refresh();
        Grid[] grids = { g1, g2, g3 };
        foreach (Grid g in grids)
            if (g.Exists(e.S("id"))) { g.SelectId(e.S("id")); break; }
    }

    string Sel() { return CurGrid().Cur; }

    void ToLabo(string st)
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette."); return; }
        try { S.SetLabo(i, st); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        Refresh();
    }

    void ToLogique()
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette en Retour Labo (LABOET / LABOFT)."); return; }
        try { S.LaboLogique(i); }
        catch (ValueError ex) { U.Warn(this, ex.Message); return; }
        Refresh();
        U.Info(this, "\u00C9tiquette " + i + " pass\u00E9e en stock logique.\nElle appara\u00EEt maintenant dans la Consultation des stocks.");
    }

    void CpyEmp()
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez d\u2019abord une \u00E9tiquette source."); return; }
        Row e = S.Label(i);
        foreach (Row x in Rows(CurGrid()))
            if ((x.S("st") == "LABOET" || x.S("st") == "LABOFT" || x.S("st") == "LOGIQUE") && x.S("emp") != e.S("emp"))
                S.X("UPDATE eti SET emp=? WHERE id=?", e.S("emp"), x.S("id"));
        Refresh();
    }

    void CpyLaize()
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez d\u2019abord une \u00E9tiquette source."); return; }
        Row e = S.Label(i);
        string lz = U.F3(S.Laize(e));
        foreach (Row x in Rows(CurGrid()))
            if (x.S("st") == "LABOET" || x.S("st") == "LABOFT")
                S.X("UPDATE eti SET ob=? WHERE id=?", "Laize " + lz, x.S("id"));
        Refresh();
    }

    void Poids()
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette."); return; }
        new PoidsDlg(App, i).ShowDialog(this);
        Refresh();
    }

    void ImprRows(List<Row> rows)
    {
        if (rows.Count == 0) { U.Warn(this, "Aucune \u00E9tiquette \u00E0 imprimer."); return; }
        U.OpenHtml(U.LabelsHtml(S, rows));
    }

    void ImprOne()
    {
        string i = Sel();
        if (string.IsNullOrEmpty(i)) { U.Warn(this, "S\u00E9lectionnez une \u00E9tiquette."); return; }
        var l = new List<Row>(); l.Add(S.Label(i));
        ImprRows(l);
    }
}
}

// ===== part07a_sim.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Simulation OF / Besoin / D\u00E9tails OF / Fiche Mod\u00E8le / Nomenclature / Achat \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictS3 = System.Collections.Generic.Dictionary<string, string>;

// \u2500\u2500 petit \u00E9crivain CSV (s\u00E9parateur ; , BOM UTF-8) \u2500\u2500
public static class Csv
{
    public static string ExportsDir()
    {
        string d = Path.Combine(U.BaseDir(), "exports");
        Directory.CreateDirectory(d);
        return d;
    }
    public static void Write(string path, string[] header, List<string[]> rows)
    {
        var sb = new StringBuilder();
        sb.AppendLine(string.Join(";", header));
        foreach (string[] r in rows)
        {
            var cells = new List<string>();
            foreach (string c in r) cells.Add((c ?? "").Replace(";", ","));
            sb.AppendLine(string.Join(";", cells));
        }
        File.WriteAllText(path, sb.ToString(), new UTF8Encoding(true));
    }
    public static void ShowCreated(Form w, string p)
    {
        U.Info(w, "Fichier cr\u00E9\u00E9 :\n" + p);
    }
}

// \u2500\u2500 accesseur dict g\u00E9n\u00E9rique partag\u00E9 \u2500\u2500
public static class Dg
{
    public static string S(IDictionary<string, object> d, string k, string dflt)
    {
        if (d != null && d.ContainsKey(k) && d[k] != null) return Convert.ToString(d[k]);
        return dflt;
    }
    public static string S(IDictionary<string, object> d, string k) { return S(d, k, ""); }
    public static double Taille(IDictionary<string, object> l, string t)
    {
        if (l == null || !l.ContainsKey("tailles")) return 0;
        var tlg = Json.Dd(l, "tailles");
        if (tlg == null || !tlg.ContainsKey(t) || tlg[t] == null) return 0;
        return U.Num(tlg[t]);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B08 : Simulation OF \u2500\u2500
public class SimOF : Win
{
    TextBox tiers;
    Dictionary<string, TextBox> V;
    Dictionary<string, CheckBox> CBox;
    HashSet<string> checkedSet;
    Grid g;
    TextBox cm;
    Dictionary<string, Label> cnt;

    public SimOF(App app) : base(app, "simulation OF", "1200x700")
    {
        V = new Dictionary<string, TextBox>();
        foreach (string k in new[] { "of", "mod", "at", "nl" }) V[k] = UI.Ent(14);
        CBox = new Dictionary<string, CheckBox>();
        CBox["sim"] = UI.Check("OFs SIM (tous tiers)"); CBox["col"] = UI.Check("OFs collections");
        CBox["suiv"] = UI.Check("OFs suivis par l'utilisateur connect\u00E9");
        CBox["sim"].Checked = true;
        checkedSet = new HashSet<string>();

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Lab(null, "Tiers"));
        tiers = UI.Ent(14);
        var cb = new ComboBox(); cb.DropDownStyle = ComboBoxStyle.DropDown; cb.Font = C.FONT; cb.Width = 120;
        cb.Items.Add("(Tous)");
        foreach (Row x in S.Tiers("client")) cb.Items.Add(x.S("code"));
        cb.TextChanged += delegate { tiers.Text = cb.Text; };
        cb.SelectedIndex = 0;
        top.Controls.Add(cb);

        foreach (var t in new[] {
                     new[] { "of", "N\u00B0 OF", "14" }, new[] { "mod", "Mod\u00E8le", "10" },
                     new[] { "at", "Atelier", "10" }, new[] { "nl", "N\u00B0Lancement", "14" } })
        {
            top.Controls.Add(UI.Lab(null, t[1]));
            V[t[0]].Width = int.Parse(t[2]) * 7 + 10;
            top.Controls.Add(V[t[0]]);
        }
        top.Controls.Add(UI.Btn("Afficher OFs \uD83D\uDD0D", delegate { Fill(); }, false, 14));

        var flt = new FlowLayoutPanel(); flt.Dock = DockStyle.Top; flt.Height = 34; flt.BackColor = Color.White;
        foreach (KeyValuePair<string, CheckBox> kv in CBox)
        {
            kv.Value.CheckedChanged += delegate { Fill(); };
            flt.Controls.Add(kv.Value);
        }

        g = new Grid(null, new[] { "S\u00E9lection", "N\u00B0 OF", "Mod\u00E8le", "Libell\u00E9 Mod\u00E8le", "Certifica", "Couleurs",
                                   "Date a r\u00E9aliser", "Heure", "D\u00E9lai Demande", "D\u00E9lai Confirme",
                                   "Date Cr\u00E9ation", "Date Eng.", "Dl" },
                     new[] { 80, 150, 90, 130, 90, 90, 100, 60, 100, 100, 100, 90, 60 }, 10, Pick, Check,
                     new int[0]);
        g.Dock = DockStyle.Fill;

        var labCm = UI.Lab(null, "Commentaires pour la Plateforme de l'OF :");
        cm = UI.Text(120, 3);

        var cntP = new TableLayoutPanel(); cntP.Dock = DockStyle.Top; cntP.Height = 32; cntP.BackColor = Color.White;
        cntP.ColumnCount = 8;
        for (int i = 0; i < 8; i++) cntP.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        cnt = new Dictionary<string, Label>();
        string[] ks = { "a", "l", "m", "d" };
        string[] ts = { "Nombre d'articles :", "Nombre de lignes :", "Nombre minutes Montage :", "Nombre minutes Dentelle :" };
        for (int i = 0; i < 4; i++)
        {
            var lab = UI.InfoLbl("0");
            cnt[ks[i]] = lab;
            cntP.Controls.Add(UI.Lab(null, ts[i]), i * 2, 0);
            cntP.Controls.Add(lab, i * 2 + 1, 0);
        }

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 36; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Valider OFs \u2714", delegate { Valider(); }, false, 14));
        bar.Controls.Add(UI.Btn("Besoin", delegate { Besoin(); }, false, 10));
        bar.Controls.Add(UI.Btn("Impr. Liste \uD83D\uDDA8", delegate { Impr(); }, false, 14));
        bar.Controls.Add(UI.Btn("Export Excel (tous tiers)", delegate { Excel(); }, false, 22));
        bar.Controls.Add(UI.Btn("Detail OF", delegate { Detail(); }, false, 10));
        var bSub = UI.Btn("Substitution", delegate { }, false, 12); bSub.Enabled = false; bar.Controls.Add(bSub);
        bar.Controls.Add(UI.Btn("Export Excel", delegate { Excel(); }, false, 12));
        bar.Controls.Add(UI.Btn("Supprimer l'OF \uD83D\uDDD1", delegate { Supprimer(); }, true, 18));
        var bPl = UI.Btn("Planning", delegate { }, false, 10); bPl.Enabled = false; bar.Controls.Add(bPl);
        bar.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 10));

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(flt, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labCm, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(cm, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(cntP, 0, 5);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 6);
        Fill();
    }

    List<KeyValuePair<Row, DictO>> RowsF()
    {
        var output = new List<KeyValuePair<Row, DictO>>();
        foreach (Row c in S.Cmds())
        {
            DictO d = S.OfdGet(c.S("n"));
            if (d == null) d = new Dictionary<string, object>();
            string of = V["of"].Text.Trim().ToUpper();
            if (of != "" && !c.S("n").StartsWith(of)) continue;
            string mod = V["mod"].Text.Trim().ToUpper();
            string dmod = Dg.S(d, "modele");
            if (mod != "" && dmod.IndexOf(mod, StringComparison.Ordinal) < 0) continue;
            string at = V["at"].Text.Trim().ToUpper();
            string dat = Dg.S(d, "atelier");
            if (at != "" && at != dat) continue;
            string nl = V["nl"].Text.Trim();
            string lan = Dg.S(d, "lancement");
            if (nl != "" && lan != nl) continue;
            string tier = tiers.Text.Trim();
            string dt = Dg.S(d, "tiers");
            if (tier != "" && tier != "(Tous)" && dt != tier) continue;
            if (CBox["col"].Checked && !d.ContainsKey("modele")) continue;
            if (CBox["suiv"].Checked && c.S("st") != "VALID\u00C9") continue;
            output.Add(new KeyValuePair<Row, DictO>(c, d));
        }
        return output;
    }

    void Fill()
    {
        var rows = new List<GRow>();
        foreach (KeyValuePair<Row, DictO> kv in RowsF())
        {
            Row c = kv.Key; DictO d = kv.Value;
            rows.Add(new GRow(c.S("n"),
                new[] { checkedSet.Contains(c.S("n")) ? "\u2611" : "\u2610", c.S("n"), Dg.S(d, "modele"), Dg.S(d, "libmodele"),
                        Dg.S(d, "certifica"), Dg.S(d, "couleurs"), Dg.S(d, "date_realiser"), Dg.S(d, "heure"),
                        Dg.S(d, "delai_demande"), Dg.S(d, "delai_confirme"), c.S("d"), Dg.S(d, "date_eng"),
                        Dg.S(d, "dl") }, false));
        }
        g.Fill(rows);
        Pick(g.Cur);
    }

    void Pick(string cur)
    {
        if (cur == null || cur == "") cur = g.Cur;
        if (cur == null || cur == "")
        {
            foreach (KeyValuePair<string, Label> kv in cnt) kv.Value.Text = "0";
            return;
        }
        foreach (KeyValuePair<Row, DictO> kv in RowsF())
        {
            if (kv.Key.S("n") != cur) continue;
            Row c = kv.Key; DictO d = kv.Value;
            long nl = S.Q("SELECT COUNT(*) n FROM cmdl WHERE n=?", cur)[0].L("n");
            cnt["a"].Text = c.S("pcs");
            cnt["l"].Text = Convert.ToString(nl);
            cnt["m"].Text = d.ContainsKey("minutes_montage") ? Convert.ToInt64(Json.N(d, "minutes_montage")).ToString() : "0";
            cnt["d"].Text = d.ContainsKey("minutes_dentelle") ? Convert.ToInt64(Json.N(d, "minutes_dentelle")).ToString() : "0";
            cm.Text = Dg.S(d, "commentaire");
            return;
        }
    }

    void Check()
    {
        if (g.Cur != null && g.Cur != "")
        {
            if (!checkedSet.Add(g.Cur)) checkedSet.Remove(g.Cur);
            string cur = g.Cur;
            Fill();
            g.SelectId(cur, false);
        }
    }

    List<string> Selection()
    {
        if (checkedSet.Count > 0) { var l = new List<string>(checkedSet); l.Sort(); return l; }
        var r = new List<string>();
        if (g.Cur != null && g.Cur != "") r.Add(g.Cur);
        return r;
    }

    void Valider()
    {
        List<string> sel = Selection();
        if (sel.Count == 0) { U.Warn(this, "Cochez (double-clic) ou s\u00E9lectionnez au moins un OF."); return; }
        foreach (string n in sel)
        {
            S.X("UPDATE cmd SET st='VALID\u00C9' WHERE n=?", n);
            S.Log("OF " + n + " valid\u00E9 (Simulation OF)");
        }
        checkedSet = new HashSet<string>();
        Fill();
        U.Info(this, sel.Count + " OF(s) valid\u00E9(s).");
    }

    void Besoin()
    {
        List<string> sel = Selection();
        if (sel.Count == 0) { U.Warn(this, "Cochez ou s\u00E9lectionnez au moins un OF."); return; }
        new SimBesoin(App, sel).Show();
    }

    void Detail()
    {
        List<string> sel = Selection();
        if (sel.Count == 0) { U.Warn(this, "Cochez ou s\u00E9lectionnez au moins un OF."); return; }
        new DetPropOF(App, sel[0]).Show();
    }

    void Impr()
    {
        var rows = RowsF();
        if (rows.Count == 0) { U.Warn(this, "Aucun OF \u00E0 imprimer."); return; }
        var tr = new StringBuilder();
        foreach (KeyValuePair<Row, DictO> kv in rows)
        {
            Row c = kv.Key; DictO d = kv.Value;
            tr.Append("<tr><td>").Append(U.Esc(c.S("n")))
               .Append("</td><td>").Append(U.Esc(Dg.S(d, "modele")))
               .Append("</td><td>").Append(U.Esc(c.S("st")))
               .Append("</td><td>").Append(c.S("pcs"))
               .Append("</td><td>").Append(U.Esc(c.S("d"))).Append("</td></tr>");
        }
        U.OpenHtml("<h3>simulation OF \u2013 Liste des OFs</h3><table><tr><th>N\u00B0 OF</th><th>Mod\u00E8le</th>" +
                   "<th>Statut</th><th>Pi\u00E8ces</th><th>Date Cr\u00E9ation</th></tr>" + tr + "</table>");
    }

    void Excel()
    {
        var rows = RowsF();
        string p = Path.Combine(Csv.ExportsDir(), "simulation-of.csv");
        var header = new[] { "N\u00B0 OF", "Mod\u00E8le", "Libell\u00E9 Mod\u00E8le", "Certifica", "Couleurs", "Date a r\u00E9aliser", "Heure",
                             "D\u00E9lai Demande", "D\u00E9lai Confirme", "Date Cr\u00E9ation", "Date Eng.", "Dl", "Pi\u00E8ces", "Statut" };
        var data = new List<string[]>();
        foreach (KeyValuePair<Row, DictO> kv in rows)
        {
            Row c = kv.Key; DictO dd = kv.Value;
            data.Add(new[] { c.S("n"), Dg.S(dd, "modele"), Dg.S(dd, "libmodele"), Dg.S(dd, "certifica"),
                             Dg.S(dd, "couleurs"), Dg.S(dd, "date_realiser"), Dg.S(dd, "heure"),
                             Dg.S(dd, "delai_demande"), Dg.S(dd, "delai_confirme"), c.S("d"),
                             Dg.S(dd, "date_eng"), Dg.S(dd, "dl"), c.S("pcs"), c.S("st") });
        }
        Csv.Write(p, header, data);
        Csv.ShowCreated(this, p);
    }

    void Supprimer()
    {
        List<string> sel = Selection();
        if (sel.Count == 0) { U.Warn(this, "Cochez ou s\u00E9lectionnez au moins un OF."); return; }
        if (!U.Ask(this, "Supprimer le(s) OF : " + string.Join(", ", sel) + " ?")) return;
        foreach (string n in sel)
        {
            try { S.DelCmd(n); }
            catch (ValueError e) { U.Warn(this, e.Message); }
        }
        checkedSet = new HashSet<string>();
        Fill();
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B09 : Simulation de besoin OF \u2500\u2500
public class SimBesoin : Win
{
    List<string> ofs;
    Grid g;

    public SimBesoin(App app, List<string> ofs) : base(app, "Simulation de besoin OF", "1000x560")
    {
        this.ofs = ofs;
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        var lab = UI.Lab(null, "OFs : " + string.Join(", ", ofs));
        g = new Grid(null, new[] { "OF", "R\u00E9f\u00E9rence", "Coloris", "D\u00E9signation", "Besoin", "Sorti", "Reste",
                                   "Disponible", "\u00C9cart", "\u00C9tat" },
                     new[] { 130, 130, 90, 180, 100, 100, 100, 110, 100, 90 }, 12, null, null,
                     new[] { 4, 5, 6, 7, 8 });
        g.Dock = DockStyle.Fill;
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 36; bar.BackColor = Color.White;
        bar.Controls.Add(UI.Btn("Export Excel \u25A6", delegate { Excel(); }, false, 16));
        bar.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 2);
        Refresh();
    }

    List<string[]> Data()
    {
        var output = new List<string[]>();
        foreach (string n in ofs)
        {
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=? ORDER BY rf", n))
            {
                Row c = S.Q("SELECT * FROM cmd WHERE n=?", n)[0];
                double dispo = S.Logique(l.S("rf"), l.S("co")) - S.Reserved(l.S("rf"), l.S("co"));
                double reste = Math.Round(l.D("q") - l.D("p"), 3);
                output.Add(new[] { n, l.S("rf"), l.S("co"), U.F3(l.D("q")), U.F3(l.D("p")), U.F3(reste),
                                   U.F3(dispo), U.F3(dispo - reste),
                                   dispo - reste >= -0.0005 ? "OK" : "MANQUE", c.S("st") });
            }
        }
        return output;
    }

    void Refresh()
    {
        var rows = new List<GRow>();
        foreach (string[] d in Data())
        {
            string rf = d[1], co = d[2];
            string lib = S.Lib("reference", rf); if (lib == null || lib == "") lib = rf;
            rows.Add(new GRow(d[0] + "|" + rf + "|" + co,
                              new[] { d[0], rf, co, lib, d[3], d[4], d[5], d[6], d[7], d[8] }, d[8] == "MANQUE"));
        }
        g.Fill(rows);
    }

    void Excel()
    {
        string p = Path.Combine(Csv.ExportsDir(), "simulation-besoin-of.csv");
        var header = new[] { "OF", "R\u00E9f\u00E9rence", "Coloris", "Besoin", "Sorti", "Reste", "Disponible", "\u00C9cart", "\u00C9tat" };
        var data = new List<string[]>();
        foreach (string[] d in Data()) data.Add(new[] { d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8] });
        Csv.Write(p, header, data);
        Csv.ShowCreated(this, p);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B010 : D\u00E9tails des Propositions d'OF \u2500\u2500
public class DetPropOF : Win
{
    public DetPropOF(App app, string of) : base(app, "D\u00E9tails des Propositions d'OF", "860x520")
    {
        var cc = S.Q("SELECT * FROM cmd WHERE n=?", of);
        if (cc.Count == 0) { Close(); return; }
        Row c = cc[0];
        DictO d = S.OfdGet(of);
        if (d == null) d = new Dictionary<string, object>();
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        var t = UI.Lab(null, Dg.S(d, "tiers", "ISALYS")); t.Font = new Font("Segoe UI", 11f, FontStyle.Bold);
        top.Controls.Add(t);
        var t2 = UI.Lab(null, of); t2.Font = new Font("Segoe UI", 11f, FontStyle.Bold);
        top.Controls.Add(t2); top.Controls.Add(UI.Lab(null, Dg.S(d, "libmodele")));
        var g = new Grid(null, new[] { "Mod\u00E8le", "Libell\u00E9", "Coloris", "Libell\u00E9", "Taille", "Qt\u00E9", "Proposition OF" },
                         new[] { 110, 200, 110, 170, 90, 110, 150 }, 12, null, null, new[] { 5 });
        g.Dock = DockStyle.Fill;

        var rows = new List<GRow>();
        var q = new Dictionary<string, double>();
        try
        {
            object parsed = Json.Parse(c.S("tl") ?? "{}");
            if (parsed is IDictionary<string, object>)
                foreach (KeyValuePair<string, object> kv in (IDictionary<string, object>)parsed)
                    q[kv.Key] = Json.N(parsed, kv.Key);
        }
        catch { }

        foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=? ORDER BY rf", of))
        {
            var n = S.Q("SELECT c FROM nom WHERE rf=? AND co=?", l.S("rf"), l.S("co"));
            double pc = n.Count > 0 ? n[0].D("c") : 0;
            foreach (Sz s in S.Sizes())
            {
                double qt;
                q.TryGetValue(s.T, out qt);
                if (qt != 0 && pc != 0)
                    rows.Add(new GRow(l.S("rf") + "|" + l.S("co") + "|" + s.T,
                        new[] { Dg.S(d, "modele"), S.Lib("reference", l.S("rf")) ?? l.S("rf"), l.S("co"),
                                S.Lib("coloris", l.S("co")) ?? l.S("co"), s.T, U.F3(qt * s.C * pc), of }, false));
            }
        }
        if (rows.Count == 0)
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=? ORDER BY rf", of))
                rows.Add(new GRow(l.S("rf") + "|" + l.S("co"),
                    new[] { Dg.S(d, "modele"), S.Lib("reference", l.S("rf")) ?? l.S("rf"), l.S("co"),
                            S.Lib("coloris", l.S("co")) ?? l.S("co"), "-", U.F3(l.D("q")), of }, false));
        g.Fill(rows);
        var b = UI.Btn("Retour \u21E5", delegate { Close(); }, false, 12);
        b.Dock = DockStyle.Top; b.TextAlign = ContentAlignment.MiddleRight;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(b, 0, 2);
    }
}
}

// ===== part07b_modeles.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Fiche Mod\u00E8le / Liste Mod\u00E8les / Nomenclature / Liste R\u00E9f / Nomenclature Achat \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;

// \u2500\u2500 Fen\u00EAtres n\u00B01/3 : Fiche Mod\u00E8le \u2500\u2500
public class ModeleFiche : Win
{
    TextBox tiers, rf;
    Dictionary<string, TextBox> V;
    Grid g;
    ComboBox ed, fi;
    List<RadioButton> valideRads;

    public ModeleFiche(App app, string tiersv = "", string refv = "") : base(app, "Fiche Mod\u00E8le", "1180x720")
    {
        tiers = UI.Ent(10); tiers.Text = tiersv;
        rf = UI.Ent(16); rf.Text = refv;
        V = new Dictionary<string, TextBox>();
        valideRads = new List<RadioButton>();

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 3;
        tlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        tlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        tlp.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 36; top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Lab(null, "Tiers :"));
        top.Controls.Add(tiers);
        top.Controls.Add(UI.Lab(null, "Mod\u00E8le technique :"));
        top.Controls.Add(rf);
        top.Controls.Add(UI.Btn("\uD83D\uDD0D", delegate { Chercher(); }, false, 4));
        top.Controls.Add(UI.Lab(null, "Valide :"));
        foreach (string tv in new[] { "Oui", "Non" })
        {
            var rad = new RadioButton(); rad.Text = tv; rad.BackColor = Color.White; rad.AutoSize = true; rad.Font = C.FONT;
            rad.Tag = tv; valideRads.Add(rad); top.Controls.Add(rad);
        }
        valideRads[0].Checked = true;

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 36; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Enregistrer(); }, false, 16));
        ed = new ComboBox(); ed.DropDownStyle = ComboBoxStyle.DropDownList; ed.Font = C.FONT; ed.Width = 110;
        ed.Items.Add("\u00C9dition"); ed.Items.Add("Nouveau"); ed.Items.Add("Supprimer");
        ed.Items.Add("Annuler"); ed.Items.Add("Dupliquer");
        ed.SelectedIndex = 0;
        bar.Controls.Add(ed);
        ed.SelectedIndexChanged += delegate { object op = ed.SelectedItem; ed.SelectedIndex = 0; Edition((string)op); };
        fi = new ComboBox(); fi.DropDownStyle = ComboBoxStyle.DropDownList; fi.Font = C.FONT; fi.Width = 110;
        fi.Items.Add("Fiche"); fi.Items.Add("PRI"); fi.Items.Add("Historique");
        fi.SelectedIndex = 0;
        bar.Controls.Add(fi);
        fi.SelectedIndexChanged += delegate { object op = fi.SelectedItem; fi.SelectedIndex = 0; Fiche((string)op); };
        bar.Controls.Add(UI.Btn("Nomenclature \uD83D\uDCCB", delegate { Nomenclature(); }, false, 18));
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        var f1 = UI.Frame("Identification"); f1.Width = 330;
        var t1 = new TableLayoutPanel(); t1.Dock = DockStyle.Fill; t1.BackColor = Color.White; t1.ColumnCount = 2;
        for (int i = 0; i < 2; i++) t1.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        f1.Controls.Add(t1);
        var f2 = UI.Frame("Attributs"); f2.Width = 330;
        var t2 = new TableLayoutPanel(); t2.Dock = DockStyle.Fill; t2.BackColor = Color.White; t2.ColumnCount = 2;
        for (int i = 0; i < 2; i++) t2.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        f2.Controls.Add(t2);

        var kv1 = new[] {
            new[] { "desc", "Description commerciale :", "22" }, new[] { "comm", "Mod\u00E8le commercial :", "18" },
            new[] { "col", "Collection :", "14" }, new[] { "thm", "Th\u00E8me :", "12" },
            new[] { "fat", "Famille atelier :", "14" }, new[] { "bar", "Quantit\u00E9 Barquette :", "8" },
            new[] { "pip", "Quantit\u00E9 Pipelette :", "8" }, new[] { "arr", "Arr\u00EAt de Production :", "8" },
            new[] { "dar", "Date Arr\u00EAt Production :", "12" } };
        for (int i = 0; i < kv1.Length; i++)
        {
            var e = UI.Ent(int.Parse(kv1[i][2])); V[kv1[i][0]] = e;
            t1.Controls.Add(UI.Lab(null, kv1[i][1]), 0, i);
            t1.Controls.Add(e, 1, i);
        }
        var kv2 = new[] {
            new[] { "marque", "Marque :", "14" }, new[] { "fam", "Famille :", "14" },
            new[] { "cert", "Certificat :", "14" }, new[] { "cao", "Code CAO :", "14" },
            new[] { "grille", "Code grille de Taille :", "14" }, new[] { "sfam", "Sous-Famille :", "14" },
            new[] { "mrp", "Cycle de Production MRP :", "14" }, new[] { "bud", "Ligne budg\u00E9taire :", "14" } };
        for (int i = 0; i < kv2.Length; i++)
        {
            var e = UI.Ent(int.Parse(kv2[i][2])); V[kv2[i][0]] = e;
            t2.Controls.Add(UI.Lab(null, kv2[i][1]), 0, i);
            t2.Controls.Add(e, 1, i);
        }

        var lc = UI.Frame("Liste des coloris du Mod\u00E8le"); lc.Dock = DockStyle.Fill;
        var lctlp = new TableLayoutPanel(); lctlp.Dock = DockStyle.Fill; lctlp.BackColor = Color.White; lctlp.ColumnCount = 1;
        lctlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        lctlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        lc.Controls.Add(lctlp);
        g = new Grid(null, new[] { "Coloris", "Libell\u00E9", "Type Mod\u00E8le", "Arr\u00EAt Prod.", "Date Arr\u00EAt Prod.",
                                   "Arr\u00EAt D\u00E9finitif", "Date Arr\u00EAt D\u00E9f.", "Code Thm/Cde", "Date sortie coll.",
                                   "Mod\u00E8le", "Saison" },
                     new[] { 70, 150, 90, 80, 100, 90, 100, 100, 100, 90, 80 }, 12, null, null, null);
        g.Dock = DockStyle.Fill;
        lctlp.Controls.Add(g, 0, 0);
        var b2 = new FlowLayoutPanel(); b2.Dock = DockStyle.Top; b2.Height = 36; b2.BackColor = Color.White;
        b2.Controls.Add(UI.Btn("Ajouter coloris \u2795", delegate { AddColoris(); }, false, 14));
        b2.Controls.Add(UI.Btn("Supprimer coloris \u2796", delegate { DelColoris(); }, true, 14));
        lctlp.Controls.Add(b2, 0, 1);

        tlp.Controls.Add(top, 0, 0);
        tlp.Controls.Add(bar, 0, 1);
        tlp.Controls.Add(f1, 0, 2);
        tlp.Controls.Add(f2, 1, 2);
        tlp.Controls.Add(lc, 2, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

        if (refv != null && refv != "") Charge();
    }

    string ValideVal()
    {
        foreach (RadioButton r in valideRads) if (r.Checked) return (string)r.Tag;
        return "Oui";
    }
    void ValideSet(string v) { foreach (RadioButton r in valideRads) r.Checked = (string)r.Tag == v; }

    void Chercher()
    {
        new ModeleListe(App, tiers.Text, delegate(string t2, string r2)
        {
            tiers.Text = t2; rf.Text = r2; Charge();
        }).Show();
    }

    Dictionary<string, object> Data()
    {
        IDictionary<string, object> d = S.ModeleGet(tiers.Text.Trim(), rf.Text.Trim());
        var m = new Dictionary<string, object>();
        if (d != null) foreach (KeyValuePair<string, object> kv in d) m[kv.Key] = kv.Value;
        m["tiers"] = tiers.Text.Trim();
        m["ref"] = rf.Text.Trim();
        m["valide"] = ValideVal();
        foreach (KeyValuePair<string, TextBox> kv in V) m[kv.Key] = kv.Value.Text;
        return m;
    }

    void Charge()
    {
        IDictionary<string, object> d = S.ModeleGet(tiers.Text.Trim(), rf.Text.Trim());
        if (d == null) d = new Dictionary<string, object>();
        ValideSet(Dg.S(d, "valide", "Oui"));
        foreach (string k in V.Keys) V[k].Text = d.ContainsKey(k) ? (Json.S(d, k) ?? "") : "";
        var rows = new List<GRow>();
        IList<object> coloris = d.ContainsKey("coloris") ? Json.L(d, "coloris") : new List<object>();
        for (int i = 0; i < coloris.Count; i++)
        {
            var c = coloris[i] as IDictionary<string, object>;
            if (c == null) continue;
            rows.Add(new GRow(Dg.S(c, "code") + "|" + i,
                new[] { Dg.S(c, "code"), Dg.S(c, "lib"), Dg.S(c, "type"), Dg.S(c, "arr"),
                        Dg.S(c, "darr"), Dg.S(c, "adef"), Dg.S(c, "dadef"), Dg.S(c, "thm"),
                        Dg.S(c, "dsort"), Dg.S(d, "comm"), Dg.S(c, "saison") }, false));
        }
        g.Fill(rows);
    }

    void AddColoris()
    {
        var w = new Form();
        w.Text = "Coloris du mod\u00E8le"; w.BackColor = Color.White;
        w.ClientSize = new Size(360, 220); w.StartPosition = FormStartPosition.CenterParent;
        var tlp = new TableLayoutPanel(); tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        var flds = new Dictionary<string, TextBox>();
        var defs = new[] { new[] { "code", "Coloris :" }, new[] { "lib", "Libell\u00E9 :" },
                           new[] { "thm", "Code Thm/Cde :" }, new[] { "saison", "Saison mod\u00E8le :" } };
        for (int i = 0; i < defs.Length; i++)
        {
            var e = UI.Ent(20); flds[defs[i][0]] = e;
            tlp.Controls.Add(UI.Lab(null, defs[i][1]), 0, i);
            tlp.Controls.Add(e, 1, i);
        }
        Button bok = UI.Btn("Ajouter \u2714", delegate
        {
            if (flds["code"].Text.Trim() == "") { U.Warn(w, "Saisissez le code coloris."); return; }
            var d = Data();
            IList<object> coloris;
            object cd; coloris = d.TryGetValue("coloris", out cd) ? (cd as IList<object>) : null;
            if (coloris == null) { coloris = new List<object>(); d["coloris"] = coloris; }
            var nc = new Dictionary<string, object>();
            foreach (KeyValuePair<string, TextBox> kv in flds) nc[kv.Key] = kv.Value.Text;
            coloris.Add(nc);
            S.ModeleSet((string)d["tiers"], (string)d["ref"], d);
            w.Close();
            Charge();
        }, false, 12);
        tlp.Controls.Add(bok, 0, 5); tlp.SetColumnSpan(bok, 2);
        w.Controls.Add(tlp);
        w.ShowDialog(this);
    }

    void DelColoris()
    {
        if (g.Cur == null || g.Cur == "") { U.Warn(this, "S\u00E9lectionnez un coloris."); return; }
        var d = Data();
        IList<object> coloris;
        object cd; coloris = d.TryGetValue("coloris", out cd) ? (cd as IList<object>) : null;
        if (coloris == null) coloris = new List<object>();
        var keep = new List<object>();
        for (int i = 0; i < coloris.Count; i++)
        {
            var c = coloris[i] as IDictionary<string, object>;
            string code = c != null ? Dg.S(c, "code") : "";
            if (code + "|" + i != g.Cur) keep.Add(coloris[i]);
        }
        d["coloris"] = keep;
        S.ModeleSet((string)d["tiers"], (string)d["ref"], d);
        Charge();
    }

    void Enregistrer()
    {
        if (tiers.Text.Trim() == "" || rf.Text.Trim() == "") { U.Warn(this, "Renseignez le tiers et le mod\u00E8le technique."); return; }
        var d = Data();
        S.ModeleSet((string)d["tiers"], (string)d["ref"], d);
        S.Log("Fiche mod\u00E8le " + (string)d["ref"] + " enregistr\u00E9e (tiers " + (string)d["tiers"] + ")");
        U.Info(this, "Mod\u00E8le " + (string)d["ref"] + " enregistr\u00E9.");
    }

    void Edition(string op)
    {
        if (op == "Nouveau")
        {
            foreach (var v in V.Values) v.Text = "";
            rf.Text = ""; tiers.Text = "";
            g.Fill(new List<GRow>());
        }
        else if (op == "Dupliquer")
        {
            rf.Text = rf.Text + "-C";
            U.Info(this, "Mod\u00E8le dupliqu\u00E9 : modifiez la r\u00E9f\u00E9rence puis Enregistrer.");
        }
        else if (op == "Supprimer")
        {
            if (rf.Text.Trim() != "" && U.Ask(this, "Supprimer le mod\u00E8le " + rf.Text + " ?"))
            {
                S.SetCfg("mdl:" + tiers.Text.Trim() + ":" + rf.Text.Trim(), "");
                Edition("Nouveau");
            }
        }
    }

    void Fiche(string op)
    {
        if (op == "PRI") U.Info(this, "PRI du mod\u00E8le : voir Historique.");
        else if (op == "Historique") new Histo(App).Show();
    }

    void Nomenclature()
    {
        if (rf.Text.Trim() == "") { U.Warn(this, "S\u00E9lectionnez ou enregistrez d'abord un mod\u00E8le technique."); return; }
        new Nomenclature(App, tiers.Text.Trim(), rf.Text.Trim()).Show();
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B02 : Liste des Mod\u00E8les techniques \u2500\u2500
public class ModeleListe : Win
{
    Action<string, string> cb;
    Dictionary<string, TextBox> F;
    Grid g;

    public ModeleListe(App app, string tiersv, Action<string, string> cb) : base(app, "Liste des Mod\u00E8les techniques", "1000x560")
    {
        this.cb = cb;
        F = new Dictionary<string, TextBox>();
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        var cr = UI.Frame("Crit\u00E8res de Recherche"); cr.Height = 140; cr.Dock = DockStyle.Top;
        var crtlp = new TableLayoutPanel(); crtlp.Dock = DockStyle.Fill; crtlp.BackColor = Color.White;
        crtlp.ColumnCount = 6;
        for (int i = 0; i < 6; i++) crtlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        var defs = new[] {
            new[] { "mt", "Mod\u00E8le technique :" }, new[] { "mc", "Mod\u00E8le commercial :" }, new[] { "cao", "Code CAO :" },
            new[] { "sai", "Saison :" }, new[] { "thm", "Th\u00E8me :" }, new[] { "fam", "Famille :" },
            new[] { "marque", "Marque :" }, new[] { "val", "Valid\u00E9 :" }, new[] { "en", "Etat Nom. :" } };
        for (int i = 0; i < defs.Length; i++)
        {
            var e = UI.Ent(14); F[defs[i][0]] = e;
            crtlp.Controls.Add(UI.Lab(null, defs[i][1]), (i % 3) * 2, i / 3);
            crtlp.Controls.Add(e, (i % 3) * 2 + 1, i / 3);
        }
        crtlp.Controls.Add(UI.Btn("% Tous les Mod\u00E8les", delegate { Tous(); }, false, 14), 0, 3);
        crtlp.Controls.Add(UI.Btn("Filtrer \uD83D\uDD0D", delegate { Fill(); }, false, 12), 1, 3);
        cr.Controls.Add(crtlp);

        g = new Grid(null, new[] { "R\u00E9f\u00E9rence", "Libell\u00E9", "Th\u00E8me", "Famille", "Saison", "Valid\u00E9", "Etat Nom", "CAO" },
                     new[] { 140, 220, 100, 110, 100, 80, 100, 90 }, 12, null, Valider, null);
        g.Dock = DockStyle.Fill;

        var b = new FlowLayoutPanel(); b.Dock = DockStyle.Top; b.Height = 36; b.BackColor = Color.White;
        b.Controls.Add(UI.Btn("Valider \u2714", delegate { Valider(); }, false, 16));
        b.Controls.Add(UI.Btn("Annuler \u2715", delegate { Close(); }, true, 12));

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(cr, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(b, 0, 2);

        Fill();
    }

    void Tous() { foreach (var v in F.Values) v.Text = ""; Fill(); }

    void Fill()
    {
        var f = new Dictionary<string, string>();
        foreach (KeyValuePair<string, TextBox> kv in F) f[kv.Key] = kv.Value.Text.Trim().ToUpper();
        var rows = new List<GRow>();
        foreach (object[] item in S.Modeles())
        {
            string tiers = (string)item[0], refv = (string)item[1];
            var d = item[2] as IDictionary<string, object>;
            if (d == null) d = new Dictionary<string, object>();
            if (f.ContainsKey("mt") && f["mt"] != "" && !refv.ToUpper().StartsWith(f["mt"])) continue;
            if (f.ContainsKey("mc") && f["mc"] != "" && !Dg.S(d, "comm").ToUpper().Contains(f["mc"])) continue;
            if (f.ContainsKey("cao") && f["cao"] != "" && !Dg.S(d, "cao").ToUpper().Contains(f["cao"])) continue;
            if (f.ContainsKey("thm") && f["thm"] != "" && !Dg.S(d, "thm").ToUpper().Contains(f["thm"])) continue;
            if (f.ContainsKey("fam") && f["fam"] != "" && !Dg.S(d, "fam").ToUpper().Contains(f["fam"])) continue;
            if (f.ContainsKey("sai") && f["sai"] != "" && !Dg.S(d, "saison").ToUpper().Contains(f["sai"])) continue;
            if (f.ContainsKey("marque") && f["marque"] != "" && !Dg.S(d, "marque").ToUpper().Contains(f["marque"])) continue;
            bool ok = Dg.S(d, "valide", "Oui") == "Oui";
            if (f.ContainsKey("val") && f["val"] == "OUI" && !ok) continue;
            var nom = S.NomenGet(tiers, refv);
            string etat = Dg.S(nom, "valide") == "Oui" ? "VALID\u00C9E"
                : (nom.ContainsKey("lignes") && Json.L(nom, "lignes").Count > 0 ? "EN COURS" : "-");
            rows.Add(new GRow(tiers + "|" + refv, new[] { refv, Dg.S(d, "desc"), Dg.S(d, "thm"), Dg.S(d, "fam"),
                                                          Dg.S(d, "saison"), Dg.S(d, "valide", "Oui"), etat, Dg.S(d, "cao") },
                     etat == "EN COURS"));
        }
        g.Fill(rows);
    }

    void Valider()
    {
        if (g.Cur == null || g.Cur == "") { U.Warn(this, "S\u00E9lectionnez un mod\u00E8le technique."); return; }
        int p = g.Cur.IndexOf('|');
        string tiers = p >= 0 ? g.Cur.Substring(0, p) : g.Cur;
        string refv = p >= 0 ? g.Cur.Substring(p + 1) : "";
        Close();
        if (cb != null) cb(tiers, refv);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B05 : Cr\u00E9ation/Modification Nomenclature \u2500\u2500
public class Nomenclature : Win
{
    string tiers, refv;
    Dictionary<string, object> d;
    Grid g;
    RadioButton valOui, valNon;
    ComboBox opt, typ;
    ListBox lcm, lmat;
    string[] szs;

    public Nomenclature(App app, string tiersv, string refv) : base(app, "Cr\u00E9ation/Modification Nomenclature", "1250x680")
    {
        tiers = tiersv; this.refv = refv;
        d = S.NomenGet(tiers, refv) as Dictionary<string, object>;
        if (d == null) d = new Dictionary<string, object>();
        var m = S.ModeleGet(tiers, refv) as Dictionary<string, object>;
        if (m == null) m = new Dictionary<string, object>();

        szs = S.Sizes().Count > 0 ? S.Sizes().Select(x => x.T).ToArray() : new[] { "34", "36", "38", "40", "42", "44" };

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new Panel(); top.Height = 140; top.Dock = DockStyle.Top; top.BackColor = Color.White;
        var toptlp = new TableLayoutPanel(); toptlp.Dock = DockStyle.Fill; toptlp.BackColor = Color.White; toptlp.ColumnCount = 5;
        for (int i = 0; i < 5; i++) toptlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        var infos = new[] {
            new[] { "Mod\u00E8le Technique :", refv }, new[] { "Mod\u00E8le CAO :", Dg.S(m, "cao") },
            new[] { "Libell\u00E9 Mod\u00E8le :", Dg.S(m, "desc") },
            new[] { "Login :", S.Cfg("login") ?? "SUPERVISEUR" } };
        for (int i = 0; i < infos.Length; i++)
        {
            toptlp.Controls.Add(UI.Lab(null, infos[i][0]), (i % 2) * 2, i / 2);
            toptlp.Controls.Add(UI.InfoLbl(infos[i][1]), (i % 2) * 2 + 1, i / 2);
        }
        toptlp.Controls.Add(UI.Lab(null, "Nomenclature Valid\u00E9e :"), 0, 2);
        valOui = new RadioButton(); valOui.Text = "Oui"; valOui.UseVisualStyleBackColor = true; valOui.AutoSize = true;
        valNon = new RadioButton(); valNon.Text = "Non"; valNon.UseVisualStyleBackColor = true; valNon.AutoSize = true;
        (Dg.S(d, "valide", "Non") == "Oui" ? valOui : valNon).Checked = true;
        toptlp.Controls.Add(valOui, 1, 2);
        toptlp.Controls.Add(valNon, 2, 2);
        toptlp.Controls.Add(UI.Lab(null, "Options Affichage :"), 0, 3);
        opt = new ComboBox(); opt.DropDownStyle = ComboBoxStyle.DropDownList; opt.Font = C.FONT; opt.Width = 120;
        opt.Items.Add("Tous"); opt.Items.Add("Pour un Pays"); opt.Items.Add("Pour un Client");
        opt.SelectedItem = Dg.S(d, "option", "Tous");
        if (opt.SelectedIndex < 0) opt.SelectedIndex = 0;
        toptlp.Controls.Add(opt, 1, 3);
        toptlp.Controls.Add(UI.Lab(null, "Type de Nomenclature :"), 2, 3);
        typ = new ComboBox(); typ.DropDownStyle = ComboBoxStyle.DropDownList; typ.Font = C.FONT; typ.Width = 120;
        typ.Items.Add("Initial"); typ.Items.Add("Fabrication"); typ.Items.Add("Achat");
        typ.SelectedItem = Dg.S(d, "type", "Initial");
        if (typ.SelectedIndex < 0) typ.SelectedIndex = 0;
        toptlp.Controls.Add(typ, 3, 3);
        top.Controls.Add(toptlp);

        var mid = new TableLayoutPanel(); mid.Dock = DockStyle.Top; mid.Height = 120; mid.BackColor = Color.White;
        mid.ColumnCount = 2;
        mid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        mid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        var fc = UI.Frame("Liste des Couleurs Mod\u00E8le"); fc.Dock = DockStyle.Fill;
        lcm = new ListBox(); lcm.Dock = DockStyle.Fill; lcm.Font = C.FONT;
        fc.Controls.Add(lcm);
        var fm = UI.Frame("Liste des Couleurs Mati\u00E8res"); fm.Dock = DockStyle.Fill;
        lmat = new ListBox(); lmat.Dock = DockStyle.Fill; lmat.Font = C.FONT; lmat.SelectionMode = SelectionMode.MultiExtended;
        fm.Controls.Add(lmat);
        mid.Controls.Add(fc, 0, 0); mid.Controls.Add(fm, 1, 0);
        foreach (object c in Json.L(m, "coloris"))
        {
            var cc = c as IDictionary<string, object>;
            if (cc != null) lcm.Items.Add(Dg.S(cc, "code") + " " + Dg.S(cc, "lib"));
        }
        foreach (Row r in S.Q("SELECT DISTINCT co, lib FROM (SELECT co, '' lib FROM eti UNION SELECT co, '' FROM nom)"))
            lmat.Items.Add(r.S("co"));

        var colsList = new List<string>(); colsList.AddRange(new[] { "R\u00E9f\u00E9rence", "Libell\u00E9", "Type Aff", "Uni Util", "Bloq", "Couleurs" });
        var wList = new List<int>(); wList.AddRange(new[] { 150, 220, 70, 70, 60, 90 });
        foreach (string t in szs) { colsList.Add(t); wList.Add(70); }
        g = new Grid(null, colsList.ToArray(), wList.ToArray(), 12, null, null,
                     Enumerable.Range(6, szs.Length).ToArray());
        g.Dock = DockStyle.Fill;

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 36; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Ajouter r\u00E9f\u00E9rence \u2795", delegate { RefDlg("ajouter"); }, false, 16));
        bar.Controls.Add(UI.Btn("Ins\u00E9rer r\u00E9f\u00E9rence \u2935", delegate { RefDlg("inserer"); }, false, 16));
        bar.Controls.Add(UI.Btn("Supprimer r\u00E9f\u00E9rence \u2716", delegate { Supprimer(); }, true, 16));
        bar.Controls.Add(UI.Btn("Remplacer r\u00E9f\u00E9rence \u21C4", delegate { RefDlg("remplacer"); }, false, 16));
        bar.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Enregistrer(); }, false, 16));
        bar.Controls.Add(UI.Btn("Achat \uD83D\uDED2", delegate { Achat(); }, false, 16));
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(mid, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 3);

        Fill();
    }

    void Fill()
    {
        var rows = new List<GRow>();
        if (d == null) d = new Dictionary<string, object>();
        IList<object> lignes;
        object lo; lignes = d.TryGetValue("lignes", out lo) ? (lo as IList<object>) : null;
        if (lignes == null) lignes = new List<object>();
        for (int i = 0; i < lignes.Count; i++)
        {
            var l = lignes[i] as IDictionary<string, object>;
            if (l == null) continue;
            string rf = Dg.S(l, "rf");
            string lib = S.Lib("reference", rf); if (lib == null || lib == "") lib = rf;
            bool bloq;
            object bo;
            bloq = l.TryGetValue("bloq", out bo) && bo != null && bo.ToString() != "" && bo.ToString() != "False" && bo.ToString() != "0";
            var vals = new List<string> { rf, lib, Dg.S(l, "type", "F"), Dg.S(l, "uni"),
                                          bloq ? "Oui" : "", Dg.S(l, "couleurs") };
            foreach (string t in szs) vals.Add(U.F3(Dg.Taille(l, t)));
            rows.Add(new GRow(Convert.ToString(i), vals.ToArray(), false));
        }
        g.Fill(rows);
    }

    void RefDlg(string mode)
    {
        new ListeRef(App, tiers, d, mode, delegate(Dictionary<string, object> dd, string mm)
        {
            d = dd;
            Fill();
            U.Info(this, "R\u00E9f\u00E9rence " + mm + " dans la nomenclature.\nPensez \u00E0 cliquer \u00AB Enregistrer \u00BB.");
        }).Show();
    }

    void Supprimer()
    {
        if (g.Cur == null) { U.Warn(this, "S\u00E9lectionnez une r\u00E9f\u00E9rence."); return; }
        var lignes = Json.L(d, "lignes");
        int idx;
        if (!int.TryParse(g.Cur, out idx) || idx < 0 || idx >= lignes.Count) return;
        lignes.RemoveAt(idx);
        d["lignes"] = lignes;
        Fill();
    }

    void EnregistrerSilence()
    {
        d["valide"] = valOui.Checked ? "Oui" : "Non";
        d["option"] = (string)opt.SelectedItem;
        d["type"] = (string)typ.SelectedItem;
        d["tiers"] = tiers;
        d["ref"] = refv;
        S.NomenSet(tiers, refv, d);
    }

    void Enregistrer()
    {
        EnregistrerSilence();
        var lignes = Json.L(d, "lignes");
        S.Log("Nomenclature du mod\u00E8le " + refv + " enregistr\u00E9e (" + lignes.Count + " r\u00E9f\u00E9rence(s))");
        U.Info(this, "Nomenclature enregistr\u00E9e.");
    }

    void Achat()
    {
        EnregistrerSilence();
        new NomAchat(App, tiers, refv).Show();
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B06 : Liste R\u00E9f\u00E9rence \u2500\u2500
public class ListeRef : Win
{
    Dictionary<string, object> nom;
    string mode;
    Action<Dictionary<string, object>, string> cb;
    Dictionary<string, TextBox> F;
    Grid g;
    ListBox ls;

    public ListeRef(App app, string tiers, IDictionary<string, object> nomData, string mode,
                    Action<Dictionary<string, object>, string> cb)
        : base(app, "Liste R\u00E9f\u00E9rence", "1000x520")
    {
        nom = new Dictionary<string, object>();
        foreach (KeyValuePair<string, object> kv in nomData) nom[kv.Key] = kv.Value;
        this.mode = mode; this.cb = cb;
        F = new Dictionary<string, TextBox>();

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 96; top.BackColor = Color.White; top.WrapContents = true;
        var vt = UI.Ent(8); vt.Text = tiers;
        top.Controls.Add(UI.Lab(null, "Tiers :")); top.Controls.Add(vt);
        var vty = UI.Combo("Tous", "Tissu", "Fourniture", "Fil", "Accessoire");
        top.Controls.Add(UI.Lab(null, "Type :")); top.Controls.Add(vty);
        var defs = new[] {
            new[] { "code", "Code" }, new[] { "lib", "Libell\u00E9" }, new[] { "four", "Code Fournisseur" },
            new[] { "fam", "Famille" }, new[] { "co", "Code Coloris" }, new[] { "marque", "Marque" } };
        foreach (var def in defs)
        {
            var e = UI.Ent(10); F[def[0]] = e;
            top.Controls.Add(UI.Lab(null, def[1] + " :"));
            top.Controls.Add(e);
        }
        top.Controls.Add(UI.Btn("Filtrer \uD83D\uDD0D", delegate { Fill(); }, false, 10));

        var mid = new TableLayoutPanel(); mid.Dock = DockStyle.Fill; mid.BackColor = Color.White;
        mid.ColumnCount = 2; mid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        mid.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        g = new Grid(null, new[] { "Marque", "R\u00E9f\u00E9rence", "Libell\u00E9", "Code Fourn" }, new[] { 100, 180, 300, 110 }, 14, null, null, null);
        g.Dock = DockStyle.Fill;
        var rt = UI.Frame("R\u00E9f envoy\u00E9es"); rt.Width = 280; rt.Dock = DockStyle.Fill;
        ls = new ListBox(); ls.Dock = DockStyle.Fill; ls.Font = C.FONT;
        rt.Controls.Add(ls);
        mid.Controls.Add(g, 0, 0); mid.Controls.Add(rt, 1, 0);

        var b = new FlowLayoutPanel(); b.Dock = DockStyle.Bottom; b.Height = 36; b.BackColor = Color.White;
        b.Controls.Add(UI.Btn("Ajouter \u2795", delegate { Ajouter(); }, false, 12));
        var bDel = UI.Btn("Supprimer \u2796", delegate { }, true, 12); bDel.Enabled = false; b.Controls.Add(bDel);
        b.Controls.Add(UI.Btn("Valider \u2714", delegate { Valider(); }, false, 14));
        b.Controls.Add(UI.Btn("Annuler \u2715", delegate { Close(); }, true, 12));

        tlp.Controls.Add(top, 0, 0);
        tlp.Controls.Add(mid, 0, 1);
        tlp.Controls.Add(b, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));

        Fill();
    }

    void Fill()
    {
        var f = new Dictionary<string, string>();
        foreach (KeyValuePair<string, TextBox> kv in F) f[kv.Key] = kv.Value.Text.Trim().ToUpper();
        var rows = new List<GRow>(); var vus = new HashSet<string>();
        foreach (Row r in S.Q("SELECT code, lib FROM tiers WHERE kind='reference' ORDER BY code"))
        {
            string code = r.S("code");
            if (f.ContainsKey("code") && f["code"] != "" && !code.ToUpper().StartsWith(f["code"])) continue;
            if (f.ContainsKey("lib") && f["lib"] != "" && !(r.S("lib") ?? "").ToUpper().Contains(f["lib"])) continue;
            rows.Add(new GRow(code, new[] { f.ContainsKey("marque") && f["marque"] != "" ? f["marque"] : "-",
                                            code, r.S("lib") ?? code, "-" }, false));
            vus.Add(code);
        }
        foreach (object oline in Json.L(nom, "lignes"))
        {
            var l = oline as IDictionary<string, object>;
            string rf = l != null ? Dg.S(l, "rf") : "";
            if (rf != "" && !vus.Contains(rf))
                rows.Add(new GRow(rf, new[] { "-", rf, S.Lib("reference", rf) ?? rf, "-" }, false));
        }
        g.Fill(rows);
        ls.Items.Clear();
        foreach (object oline in Json.L(nom, "lignes"))
        {
            var l = oline as IDictionary<string, object>;
            if (l != null) ls.Items.Add(Dg.S(l, "rf"));
        }
    }

    void Ajouter()
    {
        if (g.Cur == null || g.Cur == "") { U.Warn(this, "S\u00E9lectionnez une r\u00E9f\u00E9rence."); return; }
        var lignes = Json.L(nom, "lignes");
        var nl = new Dictionary<string, object> { { "rf", g.Cur }, { "type", "F" }, { "bloq", false },
                                                  { "couleurs", "" }, { "tailles", new Dictionary<string, object>() } };
        lignes.Add(nl);
        nom["lignes"] = lignes;
        Fill();
    }

    void Valider()
    {
        if (!nom.ContainsKey("lignes") || Json.L(nom, "lignes").Count == 0)
        { U.Warn(this, "Ajoutez au moins une r\u00E9f\u00E9rence."); return; }
        Close();
        if (cb != null) cb(nom, mode);
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B07 : Nomenclature Achat et Fabrication \u2500\u2500
public class NomAchat : Win
{
    string tiers, refv;
    ListBox lc, lmat;
    Grid g1, g2;

    public NomAchat(App app, string tiersv, string refv) : base(app, "Nomenclature Achat et Fabrication", "1250x660")
    {
        tiers = tiersv; this.refv = refv;
        var nom = S.NomenGet(tiers, refv);
        var m = S.ModeleGet(tiers, refv);
        if (m == null) m = new Dictionary<string, object>();

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        tlp.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        tlp.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        Body.Controls.Add(tlp);

        var top = new Panel(); top.Dock = DockStyle.Top; top.Height = 96; top.BackColor = Color.White;
        var topFlow = new FlowLayoutPanel(); topFlow.Dock = DockStyle.Top; topFlow.Height = 34; topFlow.BackColor = Color.White; topFlow.WrapContents = false;
        topFlow.Controls.Add(UI.Lab(null, "Mod\u00E8le technique : " + refv + "    Mod\u00E8le CAO : " + Dg.S(m, "cao") +
                                        "    Libell\u00E9 : " + Dg.S(m, "desc")));
        topFlow.Controls.Add(UI.Btn("Export Excel \uD83D\uDCCA", delegate { Export(); }, false, 16));
        topFlow.Controls.Add(UI.Btn("Retour \u23EE", delegate { Close(); }, true, 12));

        var topRow2 = new FlowLayoutPanel(); topRow2.Dock = DockStyle.Top; topRow2.Height = 56; topRow2.BackColor = Color.White;
        topRow2.Controls.Add(UI.Lab(null, "S\u00E9lectionner le coloris :"));
        lc = new ListBox(); lc.Width = 130; lc.Height = 48; lc.Font = C.FONT; lc.SelectionMode = SelectionMode.One;
        lmat = new ListBox(); lmat.Width = 130; lmat.Height = 48; lmat.Font = C.FONT; lmat.SelectionMode = SelectionMode.One;
        topRow2.Controls.Add(lc); topRow2.Controls.Add(lmat);
        top.Controls.Add(topFlow);
        top.Controls.Add(topRow2);

        foreach (object c in Json.L(m, "coloris"))
        {
            var cc = c as IDictionary<string, object>;
            if (cc != null) lc.Items.Add(Dg.S(cc, "code") + " " + Dg.S(cc, "lib"));
        }
        var cols = new SortedSet<string>();
        foreach (Row r in S.Q("SELECT DISTINCT co FROM eti")) cols.Add(r.S("co"));
        foreach (string c in cols) lmat.Items.Add(c);
        lc.SelectedIndexChanged += delegate { Fill(); };
        lmat.SelectedIndexChanged += delegate { Fill(); };

        string[] sz = S.Sizes().Count > 0 ? S.Sizes().Select(x => x.T).ToArray() : new[] { "34", "36", "38", "40", "42", "44" };

        var f1 = UI.Frame("REFERENCES"); f1.Dock = DockStyle.Fill;
        var f1tlp = new TableLayoutPanel(); f1tlp.Dock = DockStyle.Fill; f1tlp.BackColor = Color.White; f1tlp.ColumnCount = 1;
        f1.Controls.Add(f1tlp);
        g1 = new Grid(null, new[] { "Ref - Niv", "Libell\u00E9", "Type Aff", "Unit\u00E9", "util", "Large", "Pays", "Client" },
                      new[] { 140, 220, 70, 70, 60, 70, 60, 70 }, 14, null, null, null);
        g1.Dock = DockStyle.Fill;
        f1tlp.Controls.Add(g1, 0, 0);

        var f2 = UI.Frame("COLORIS"); f2.Dock = DockStyle.Fill;
        var f2tlp = new TableLayoutPanel(); f2tlp.Dock = DockStyle.Fill; f2tlp.BackColor = Color.White; f2tlp.ColumnCount = 1;
        f2.Controls.Add(f2tlp);
        var cols2 = new List<string>(); cols2.Add("062"); cols2.Add("Libell\u00E9 coloris");
        var ws2 = new List<int>(); ws2.Add(90); ws2.Add(160);
        var right2 = new List<int>();
        for (int i = 0; i < sz.Length; i++) { cols2.Add(sz[i]); ws2.Add(70); right2.Add(2 + i); }
        g2 = new Grid(null, cols2.ToArray(), ws2.ToArray(), 14, null, null, right2.ToArray());
        g2.Dock = DockStyle.Fill;
        f2tlp.Controls.Add(g2, 0, 0);

        tlp.Controls.Add(top, 0, 0);
        tlp.SetColumnSpan(top, 2);
        tlp.Controls.Add(f1, 0, 1);
        tlp.Controls.Add(f2, 1, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

        Fill();
    }

    void Fill()
    {
        var nom = S.NomenGet(tiers, refv);
        var r1 = new List<GRow>();
        foreach (object oline in Json.L(nom, "lignes"))
        {
            var l = oline as IDictionary<string, object>;
            if (l == null) continue;
            string rf = Dg.S(l, "rf");
            string lib = S.Lib("reference", rf); if (lib == null || lib == "") lib = rf;
            var q = S.Q("SELECT c FROM nom WHERE rf=?", rf);
            string util = q.Count > 0 ? U.F3(q[0].D("c")) : "-";
            r1.Add(new GRow(rf, new[] { rf, lib, Dg.S(l, "type", "F"), "M", Dg.S(l, "uni"), util,
                                        Dg.S(l, "pays"), Dg.S(l, "client") }, false));
        }
        g1.Fill(r1);

        string color = "";
        if (lc.SelectedIndex >= 0 && lc.SelectedItem != null) color = ((string)lc.SelectedItem).Split(' ')[0];
        else if (lmat.SelectedIndex >= 0 && lmat.SelectedItem != null)
            color = ((string)lmat.SelectedItem).Split(' ')[0];

        string[] sz = S.Sizes().Count > 0 ? S.Sizes().Select(x => x.T).ToArray() : new[] { "34", "36", "38", "40", "42", "44" };
        var r2 = new List<GRow>();
        foreach (object oline in Json.L(nom, "lignes"))
        {
            var l = oline as IDictionary<string, object>;
            if (l == null) continue;
            var vals = new List<string> { color, S.Lib("coloris", color) ?? color };
            foreach (string t in sz) vals.Add(U.F3(Dg.Taille(l, t)));
            r2.Add(new GRow(Dg.S(l, "rf"), vals.ToArray(), false));
        }
        g2.Fill(r2);
    }

    void Export()
    {
        var fd = new SaveFileDialog();
        fd.FileName = "nomenclature-" + refv + ".csv";
        fd.Filter = "CSV / Excel|*.csv";
        if (fd.ShowDialog(this) != DialogResult.OK) return;
        string p = fd.FileName;
        var nom = S.NomenGet(tiers, refv);
        string[] sz = S.Sizes().Count > 0 ? S.Sizes().Select(x => x.T).ToArray() : new[] { "34", "36", "38", "40", "42", "44" };
        var rows = new List<string[]>();
        foreach (object oline in Json.L(nom, "lignes"))
        {
            var l = oline as IDictionary<string, object>;
            if (l == null) continue;
            var vals = new List<string> { Dg.S(l, "rf"), S.Lib("reference", Dg.S(l, "rf")) ?? "", Dg.S(l, "type", "F") };
            foreach (string t in sz) vals.Add(U.F3(Dg.Taille(l, t)));
            rows.Add(vals.ToArray());
        }
        var header = new List<string>();
        header.Add("Nomenclature"); header.Add(refv); header.Add("R\u00E9f\u00E9rence"); header.Add("Libell\u00E9");
        header.Add("Type"); header.Add("Tiers");
        var data = new List<string[]>();
        foreach (string[] r in rows) data.Add(r);
        Csv.Write(p, header.ToArray(), data);
        try { System.Diagnostics.Process.Start(p); } catch { }
        S.Log("Nomenclature " + refv + " export\u00E9e (" + p + ")");
    }
}
}

// ===== part08_ai_labo.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 Moteur IA (lecture seule) / Assistant IA / Param Tests / Laboratoire \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;

// \u2500\u2500 Moteur IA \u2013 lecture seule, cach\u00E9 (\u00E9tapes 1+2) \u2500\u2500
public class AI
{
    Store S;
    public AI(Store S) { this.S = S; }

    public Dictionary<string, long> Vue()
    {
        var r = new Dictionary<string, long>();
        foreach (string t in new[] { "rec", "eti", "cmd", "cmdl", "hist", "tiers", "nom", "cfg" })
            r[t] = S.Q("SELECT COUNT(*) c FROM " + t)[0].L("c");
        return r;
    }

    public List<object[]> AlertesManque()
    {
        var besoin = new SortedDictionary<string, double>();
        foreach (Row l in S.Q("SELECT rf, co, q, p FROM cmdl"))
        {
            double r = Math.Round(l.D("q") - l.D("p"), 3);
            if (r > 0.0005)
            {
                string k = l.S("rf") + "|" + l.S("co");
                double b; besoin.TryGetValue(k, out b);
                besoin[k] = Math.Round(b + r, 3);
            }
        }
        var output = new List<object[]>();
        foreach (KeyValuePair<string, double> kv in besoin)
        {
            string[] p = kv.Key.Split('|');
            string rf = p[0], co = p[1];
            double dispo = S.Logique(rf, co) - S.Reserved(rf, co);
            if (dispo < kv.Value)
                output.Add(new object[] { rf, co, kv.Value, dispo, Math.Round(kv.Value - dispo, 3) });
        }
        return output;
    }

    public List<object[]> Anomalies()
    {
        var tot = new Dictionary<string, double>();
        var n = new Dictionary<string, int>();
        var recent = new Dictionary<string, List<double>>();
        foreach (DictO m in S.Moves())
        {
            string rf = Json.S(m, "rf");
            double qt = Json.N(m, "qt");
            tot[rf] = (tot.ContainsKey(rf) ? tot[rf] : 0) + qt;
            n[rf] = (n.ContainsKey(rf) ? n[rf] : 0) + 1;
            List<double> lst;
            if (!recent.TryGetValue(rf, out lst)) { lst = new List<double>(); recent[rf] = lst; }
            lst.Add(qt);
        }
        var output = new List<object[]>();
        foreach (KeyValuePair<string, List<double>> kv in recent)
        {
            string rf = kv.Key;
            if (n.ContainsKey(rf) && n[rf] >= 3 && kv.Value.Count > 0)
            {
                double moy = tot[rf] / n[rf];
                double last = kv.Value[0];
                if (moy > 0 && last > 2 * moy)
                    output.Add(new object[] { rf, last, Math.Round(moy, 3), n[rf] });
            }
        }
        return output.Take(10).ToList();
    }

    public List<object[]> Prevision()
    {
        var conso = new SortedDictionary<string, List<KeyValuePair<string, double>>>();
        foreach (DictO m in S.Moves())
        {
            string rf = Json.S(m, "rf");
            List<KeyValuePair<string, double>> lst;
            if (!conso.TryGetValue(rf, out lst)) { lst = new List<KeyValuePair<string, double>>(); conso[rf] = lst; }
            lst.Add(new KeyValuePair<string, double>(Json.S(m, "co"), Json.N(m, "qt")));
        }
        var output = new List<object[]>();
        foreach (KeyValuePair<string, List<KeyValuePair<string, double>>> kv in conso)
        {
            if (kv.Value.Count >= 2)
            {
                double moy = Math.Round(kv.Value.Sum(x => x.Value) / kv.Value.Count, 3);
                double dispo = kv.Value.Sum(x => S.Logique(kv.Key, x.Key));
                output.Add(new object[] { kv.Key, moy, kv.Value.Count, Math.Round(dispo, 3) });
            }
        }
        return output.Take(12).ToList();
    }

    public bool Verifier()
    {
        string[] tabs = { "rec", "eti", "cmd", "cmdl" };
        var before = new Dictionary<string, long>();
        foreach (string t in tabs) before[t] = S.Q("SELECT COUNT(*) c FROM " + t)[0].L("c");
        AlertesManque(); Anomalies(); Prevision();
        foreach (string t in tabs)
            if (before[t] != S.Q("SELECT COUNT(*) c FROM " + t)[0].L("c")) return false;
        return true;
    }
}

// \u2500\u2500 Fen\u00EAtre Assistant IA \u2500\u2500
public class AIDlg : Win
{
    AI ai;
    TextBox txt;

    public AIDlg(App app) : base(app, "Assistant IA \u2013 Pro Textile Syst\u00E8me", "1080x620")
    {
        ai = new AI(S);
        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);
        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.Controls.Add(UI.Lab(null, "\uD83E\uDDE0 Moteur IA : lecture seule \u00B7 aucune donn\u00E9e envoy\u00E9e sur Internet \u00B7 " +
                                      "aucune \u00E9criture dans la base sans votre validation."));
        top.Controls.Add(UI.Btn("Diagnostic de v\u00E9rification \u2714", delegate { Diag(); }, false, 16));
        txt = new TextBox();
        txt.Multiline = true; txt.ReadOnly = false; txt.ScrollBars = ScrollBars.Both; txt.WordWrap = false;
        txt.Font = new Font("Segoe UI", 10f); txt.Dock = DockStyle.Fill;
        var b = UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12);
        b.Dock = DockStyle.Top; b.TextAlign = ContentAlignment.MiddleRight;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(txt, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(b, 0, 2);
        Afficher();
    }

    void Afficher()
    {
        var v = ai.Vue();
        var am = ai.AlertesManque();
        var an = ai.Anomalies();
        var pv = ai.Prevision();
        var t = new StringBuilder();
        t.Append("\uD83E\uDDE0 ASSISTANT IA \u2013 DIAGNOSTIC\r\n").Append(new string('=', 70)).Append("\r\n");
        t.Append("Tables lues (liaison automatique avec tout le syst\u00E8me) :\r\n");
        foreach (KeyValuePair<string, long> kv in v)
            t.Append("  \u2022 ").Append(kv.Key).Append(" : ").Append(kv.Value).Append(" enregistrement(s)\r\n");
        t.Append("\r\n\u26A0 ALERTES DE MANQUE (").Append(am.Count).Append(") \u2014 avant cr\u00E9ation de L :\r\n");
        foreach (object[] x in am.Take(15))
            t.Append("  \u2022 ").Append(x[0]).Append(" / ").Append(x[1]).Append(" : besoin ").Append(U.F3((double)x[2]))
             .Append(", dispo ").Append(U.F3((double)x[3])).Append(" \u2192 manque ").Append(U.F3((double)x[4])).Append("\r\n");
        if (am.Count == 0) t.Append("  Aucun manque d\u00E9tect\u00E9.\r\n");
        t.Append("\r\n\uD83D\uDCCA ANOMALIES DE CONSOMMATION (").Append(an.Count).Append(") :\r\n");
        foreach (object[] x in an)
            t.Append("  \u2022 ").Append(x[0]).Append(" : dernier pr\u00E9l\u00E8vement ").Append(U.F3((double)x[1]))
             .Append(" (moyenne ").Append(U.F3((double)x[2])).Append(" sur ").Append(x[3]).Append(" sorties)\r\n");
        if (an.Count == 0) t.Append("  Aucune anomalie.\r\n");
        t.Append("\r\n\uD83D\uDCC8 PR\u00C9VISIONS (besoin moyen par r\u00E9f\u00E9rence) :\r\n");
        foreach (object[] x in pv)
            t.Append("  \u2022 ").Append(x[0]).Append(" : ").Append(U.F3((double)x[1])).Append("/sortie en moyenne (")
             .Append(x[2]).Append(" sorties), dispo actuel ").Append(U.F3((double)x[3])).Append("\r\n");
        if (pv.Count == 0) t.Append("  Pas encore assez d'historique.\r\n");
        txt.Text = t.ToString();
    }

    void Diag()
    {
        bool ok = ai.Verifier();
        if (ok)
            U.Info(this, "\u2714 V\u00C9RIFICATION R\u00C9USSIE\n\nLe moteur IA a lu les tables et n'a modifi\u00E9 AUCUNE donn\u00E9e.\nAucune connexion Internet n'a \u00E9t\u00E9 utilis\u00E9e.");
        else
            U.Warn(this, "\u00C9cart d\u00E9tect\u00E9 lors de la v\u00E9rification.");
        Afficher();
    }
}

// \u2500\u2500 Fen\u00EAtres n\u00B06/7 : Param\u00E9trage de v\u00E9rification des tests Labo \u2500\u2500
public class ParamTests : Win
{
    TextBox vt, vr, vp;
    Grid g1, g2;
    DictO d;

    public ParamTests(App app) : base(app, "Fiche Mati\u00E8re Premi\u00E8re \u2013 Param Tests", "1100x620")
    {
        d = new Dictionary<string, object> { { "tests", new List<object>() }, { "mesures", new List<object>() } };

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = UI.Frame("Fiche Mati\u00E8re Premi\u00E8re"); top.Height = 110; top.Dock = DockStyle.Top;
        var toptlp = new TableLayoutPanel(); toptlp.Dock = DockStyle.Fill; toptlp.BackColor = Color.White; toptlp.ColumnCount = 5;
        for (int i = 0; i < 5; i++) toptlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        vt = UI.Ent(10);
        new CodeField(toptlp, App, "client", "Tiers", vt, 0, 10);
        var labRef = UI.Lab(null, "Code R\u00E9f\u00E9rence Technique :");
        vr = UI.Ent(16);
        toptlp.Controls.Add(labRef, 0, 1);
        toptlp.Controls.Add(vr, 1, 1);
        toptlp.Controls.Add(UI.Btn("Charger \uD83D\uDCC2", delegate { Charge(); }, false, 10), 2, 1);
        toptlp.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Enregistrer(); }, false, 14), 3, 1);
        toptlp.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12), 4, 1);
        top.Controls.Add(toptlp);

        var f1 = UI.Frame("TESTS ASSOCI\u00C9S \u00C0 LA R\u00C9F\u00C9RENCE"); f1.Dock = DockStyle.Fill;
        var f1tlp = new TableLayoutPanel(); f1tlp.Dock = DockStyle.Fill; f1tlp.BackColor = Color.White; f1tlp.ColumnCount = 1;
        f1tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        f1tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        f1.Controls.Add(f1tlp);
        g1 = new Grid(null, new[] { "Code Test", "Libell\u00E9 Test", "%" }, new[] { 140, 280, 80 }, 5, null, null, new[] { 2 });
        g1.Dock = DockStyle.Fill;
        f1tlp.Controls.Add(g1, 0, 0);
        var b1 = new FlowLayoutPanel(); b1.Dock = DockStyle.Top; b1.Height = 34; b1.BackColor = Color.White;
        b1.Controls.Add(UI.Btn("+", delegate { AjoutTest(); }, false, 4));
        b1.Controls.Add(UI.Btn("\u2212", delegate { SuppTest(); }, true, 4));
        b1.Controls.Add(UI.Lab(null, "Pourcentage Visitage :"));
        vp = UI.Ent(8); vp.Text = "0";
        b1.Controls.Add(vp);
        f1tlp.Controls.Add(b1, 0, 1);

        var f2 = UI.Frame("MESURES ET TOL\u00C9RANCES DU TEST"); f2.Dock = DockStyle.Fill;
        var f2tlp = new TableLayoutPanel(); f2tlp.Dock = DockStyle.Fill; f2tlp.BackColor = Color.White; f2tlp.ColumnCount = 1;
        f2tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        f2tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        f2.Controls.Add(f2tlp);
        g2 = new Grid(null, new[] { "Code", "Mesure", "Minimum", "Maximum", "Oui / Non" },
                      new[] { 80, 260, 120, 120, 100 }, 6, null, null, new[] { 2, 3 });
        g2.Dock = DockStyle.Fill;
        f2tlp.Controls.Add(g2, 0, 0);
        var b2 = new FlowLayoutPanel(); b2.Dock = DockStyle.Top; b2.Height = 34; b2.BackColor = Color.White;
        b2.Controls.Add(UI.Btn("Ajouter mesure \u2795", delegate { AjoutMesure(); }, false, 14));
        b2.Controls.Add(UI.Btn("Supprimer mesure \u2796", delegate { SuppMesure(); }, true, 14));
        f2tlp.Controls.Add(b2, 0, 1);

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(f1, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(f2, 0, 2);

        Fill();
    }

    List<object> Tests()
    {
        object o; return d.TryGetValue("tests", out o) ? (o as List<object>) ?? new List<object>() : new List<object>();
    }
    List<object> Mesures()
    {
        object o; return d.TryGetValue("mesures", out o) ? (o as List<object>) ?? new List<object>() : new List<object>();
    }

    void Charge()
    {
        d = S.LaboParam(vr.Text.Trim().ToUpper(), vt.Text.Trim().ToUpper());
        if (d == null) d = new Dictionary<string, object>();
        vp.Text = Convert.ToString(d.ContainsKey("pct") ? d["pct"] : "0");
        Fill();
    }

    void Fill()
    {
        var r1 = new List<GRow>();
        foreach (object o in Tests())
        {
            var t = o as IDictionary<string, object>;
            if (t == null) continue;
            r1.Add(new GRow(Dpub.S(t, "code"), new[] { Dpub.S(t, "code"), Dpub.S(t, "lib"),
                                                       U.F3(t.ContainsKey("pct") ? U.Num(t["pct"]) : 0) }, false));
        }
        g1.Fill(r1);
        var r2 = new List<GRow>();
        int i = 0;
        foreach (object o in Mesures())
        {
            var m = o as IDictionary<string, object>;
            if (m == null) continue;
            string code = m.ContainsKey("code") ? Dpub.S(m, "code") : Convert.ToString(i);
            r2.Add(new GRow(Convert.ToString(i), new[] { code, Dpub.S(m, "mesure"),
                                                         U.F3(m.ContainsKey("min") ? U.Num(m["min"]) : 0),
                                                         U.F3(m.ContainsKey("max") ? U.Num(m["max"]) : 0),
                                                         m.ContainsKey("oin") && m["oin"].ToString() != "False" && m["oin"].ToString() != "0" ? "Oui" : "Non" }, false));
            i++;
        }
        g2.Fill(r2);
    }

    void AjoutTest()
    {
        var w = new Form();
        w.Text = "Liste Test Labo"; w.BackColor = Color.White;
        w.ClientSize = new Size(420, 300); w.StartPosition = FormStartPosition.CenterParent;
        var lb = new ListBox(); lb.Font = C.FONT; lb.Dock = DockStyle.Fill;
        foreach (string[] tl in C.TESTS_LABO) lb.Items.Add(tl[0].PadRight(8) + " " + tl[1]);
        w.Controls.Add(lb);
        var bok = UI.Btn("Valider \u2714", delegate
        {
            if (lb.SelectedIndex < 0) { U.Warn(w, "S\u00E9lectionnez un test."); return; }
            string[] t = C.TESTS_LABO[lb.SelectedIndex];
            var tests = Tests();
            tests.Add(new Dictionary<string, object> { { "code", t[0] }, { "lib", t[1] }, { "pct", U.Num(vp.Text) } });
            d["tests"] = tests;
            w.Close();
            Fill();
        }, false, 14);
        bok.Dock = DockStyle.Bottom; bok.Height = 34;
        w.Controls.Add(bok);
        w.ShowDialog(this);
    }

    void SuppTest()
    {
        if (g1.Cur == null || g1.Cur == "") { U.Warn(this, "S\u00E9lectionnez un test."); return; }
        var keep = new List<object>();
        foreach (object o in Tests())
        {
            var t = o as IDictionary<string, object>;
            if (t == null || Dpub.S(t, "code") != g1.Cur) keep.Add(o);
        }
        d["tests"] = keep;
        Fill();
    }

    void AjoutMesure()
    {
        var w = new Form();
        w.Text = "Mesure et tol\u00E9rances"; w.BackColor = Color.White;
        w.ClientSize = new Size(360, 240); w.StartPosition = FormStartPosition.CenterParent;
        var tlp = new TableLayoutPanel(); tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        var vm = UI.Ent(16); var vn = UI.Ent(16); var vx = UI.Ent(16);
        tlp.Controls.Add(UI.Lab(null, "Mesure :"), 0, 0); tlp.Controls.Add(vm, 1, 0);
        tlp.Controls.Add(UI.Lab(null, "Minimum :"), 0, 1); tlp.Controls.Add(vn, 1, 1);
        tlp.Controls.Add(UI.Lab(null, "Maximum :"), 0, 2); tlp.Controls.Add(vx, 1, 2);
        var oin = UI.Check("Obligatoire (Oui)"); oin.Checked = true;
        tlp.Controls.Add(oin, 0, 3); tlp.SetColumnSpan(oin, 2);
        var fr = new FlowLayoutPanel(); fr.BackColor = Color.White;
        fr.Controls.Add(UI.Btn("Ajouter \u2714", delegate
        {
            if (vm.Text.Trim() == "") { U.Warn(w, "Saisissez la mesure."); return; }
            var mesures = Mesures();
            mesures.Add(new Dictionary<string, object> { { "mesure", vm.Text }, { "min", U.Num(vn.Text) },
                                                         { "max", U.Num(vx.Text) }, { "oin", oin.Checked } });
            d["mesures"] = mesures;
            w.Close();
            Fill();
        }, false, 12));
        fr.Controls.Add(UI.Btn("Annuler \u2715", delegate { w.Close(); }, true, 12));
        tlp.Controls.Add(fr, 0, 4); tlp.SetColumnSpan(fr, 2);
        w.Controls.Add(tlp);
        w.ShowDialog(this);
    }

    void SuppMesure()
    {
        if (g2.Cur == null || g2.Cur == "") { U.Warn(this, "S\u00E9lectionnez une mesure."); return; }
        var mesures = Mesures();
        int idx;
        if (!int.TryParse(g2.Cur, out idx) || idx < 0 || idx >= mesures.Count) return;
        mesures.RemoveAt(idx);
        d["mesures"] = mesures;
        Fill();
    }

    void Enregistrer()
    {
        if (vr.Text.Trim() == "") { U.Warn(this, "Indiquez la r\u00E9f\u00E9rence."); return; }
        d["pct"] = vp.Text;
        S.LaboParamSet(vr.Text.Trim().ToUpper(), vt.Text.Trim().ToUpper(), d);
        S.Log("Param Tests Labo enregistr\u00E9s pour " + vr.Text + " (" + Tests().Count + " test(s), " + Mesures().Count + " mesure(s))");
        U.Info(this, "Param\u00E9trage des tests enregistr\u00E9.\nIl s'appliquera automatiquement dans la fen\u00EAtre Laboratoire.");
    }
}

static class Dpub
{
    public static string S(IDictionary<string, object> d, string k)
    {
        return d != null && d.ContainsKey(k) && d[k] != null ? Convert.ToString(d[k]) : "";
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B05 : Laboratoire \u2500\u2500
public class Laboratoire : Win
{
    Row e;
    TextBox ve;
    Grid g;
    Dictionary<string, TextBox> V;
    CheckBox ann;
    TextBox date;

    public Laboratoire(App app) : base(app, "Laboratoire \u2013 R\u00E9sultats des tests", "1150x660")
    {
        e = null;
        if (!PromptPwd())
        {
            Close();
            return;
        }

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 36; top.BackColor = Color.White;
        top.Controls.Add(UI.Lab(null, "Entrez un N\u00B0 d'\u00E9tiquette de test :"));
        ve = UI.Ent(18);
        top.Controls.Add(ve);
        top.Controls.Add(UI.Btn("Afficher \uD83D\uDD0D", delegate { Chercher(); }, false, 12));
        top.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        g = new Grid(null, new[] { "Chrono", "Etiquette", "Test", "T", "I", "O", "Mesure", "R\u00E9sultat" },
                     new[] { 60, 110, 180, 40, 40, 40, 140, 90 }, 7, null, null, new[] { 7 });
        g.Dock = DockStyle.Fill;

        var f = UI.Frame("Saisie du test en cours"); f.Height = 165; f.Dock = DockStyle.Top;
        var ftlp = new TableLayoutPanel(); ftlp.Dock = DockStyle.Fill; ftlp.BackColor = Color.White; ftlp.ColumnCount = 8;
        for (int i = 0; i < 8; i++) ftlp.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        V = new Dictionary<string, TextBox>();
        var defs = new[] {
            new[] { "et", "Etiquette :" }, new[] { "lg", "Longueur Ann. :" }, new[] { "ti", "Tiers :" },
            new[] { "rf", "R\u00E9f\u00E9rence :" }, new[] { "co", "Coloris :" }, new[] { "te", "Test :" },
            new[] { "ob", "Observation Test :" }, new[] { "me", "Mesure :" },
            new[] { "mn", "Tol\u00E9rance Mini :" }, new[] { "mx", "Tol\u00E9rance Maxi :" }, new[] { "re", "R\u00E9sultat :" } };
        for (int i = 0; i < defs.Length; i++)
        {
            var t = UI.Ent(12); V[defs[i][0]] = t;
            ftlp.Controls.Add(UI.Lab(null, defs[i][1]), (i % 4) * 2, i / 4);
            ftlp.Controls.Add(t, (i % 4) * 2 + 1, i / 4);
        }
        ann = UI.Check("Test Annul\u00E9");
        ftlp.Controls.Add(ann, 6, 2);
        ftlp.Controls.Add(UI.Lab(null, "Date :"), 7, 2);
        date = UI.Ent(10); date.Text = U.TodayFr();
        ftlp.Controls.Add(date, 8, 2);
        f.Controls.Add(ftlp);

        var b = new FlowLayoutPanel(); b.Dock = DockStyle.Top; b.Height = 36; b.BackColor = Color.White;
        b.Controls.Add(UI.Btn("Enregistrer le r\u00E9sultat \uD83D\uDCBE", delegate { Enregistrer(); }, false, 20));
        b.Controls.Add(UI.Btn("Imprimer l'\u00E9tiquette Zebra \u25A5", delegate { Imprimer(); }, false, 20));
        var help = new Label();
        help.Text = "Le test s\u00E9lectionn\u00E9 se remplit apr\u00E8s \u00AB Afficher \u00BB. \u00C0 la fin des tests, l'\u00E9tiquette passe automatiquement en LABO FT.";
        help.Font = C.FONT; help.BackColor = Color.White; help.AutoSize = true;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(f, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(b, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(help, 0, 4);
    }

    bool PromptPwd()
    {
        var w = new Form();
        w.Text = "Acc\u00E8s Laboratoire"; w.BackColor = Color.White;
        w.ClientSize = new Size(260, 130); w.StartPosition = FormStartPosition.CenterParent;
        w.FormBorderStyle = FormBorderStyle.FixedDialog;
        bool ok = false;
        var lab = UI.Lab(null, "Mot de passe :"); lab.Location = new Point(20, 12);
        var vp = new TextBox(); vp.Font = C.FONT; vp.PasswordChar = '\u2022';
        vp.Location = new Point(20, 36); vp.Width = 200;
        var bok = UI.Btn("Valider \u2714", delegate
        {
            if (vp.Text != (S.Cfg("pwd") ?? "1234")) { U.Warn(w, "Mot de passe incorrect."); return; }
            ok = true; w.Close();
        }, false, 12);
        bok.Location = new Point(20, 64);
        w.Controls.Add(lab); w.Controls.Add(vp); w.Controls.Add(bok);
        w.FormClosed += delegate { if (!ok) this.BeginInvoke((MethodInvoker)delegate { }); };
        w.ShowDialog(this);
        return ok;
    }

    void Chercher()
    {
        string eid = ve.Text.Trim();
        Row e2 = S.Label(eid);
        if (e2 == null || !(e2.S("st") == "RECEP" || e2.S("st") == "LABOET" || e2.S("st") == "LABOFT"))
        {
            U.Warn(this, "\u00C9tiquette introuvable (ou d\u00E9j\u00E0 sortie).\nScannez le code-barres d'une \u00E9tiquette r\u00E9ceptionn\u00E9e.");
            return;
        }
        e = e2;
        V["et"].Text = e2.S("id");
        V["ti"].Text = e2.S("fo");
        V["rf"].Text = e2.S("rf");
        V["co"].Text = e2.S("co");
        V["lg"].Text = U.F3(e2.D("qt"));
        DictO p = S.LaboParam(e2.S("rf"), null);
        if (p == null) p = new Dictionary<string, object>();
        DictO res = S.LaboRes(eid);
        if (res == null) res = new Dictionary<string, object>();
        var fait = new HashSet<string>();
        foreach (object o in Json.L(res, "tests"))
        {
            var t = o as IDictionary<string, object>;
            if (t != null) fait.Add(Dpub.S(t, "test"));
        }
        var rows = new List<GRow>();
        IList<object> tests;
        object to; tests = p.TryGetValue("tests", out to) ? (to as IList<object>) : null;
        if (tests == null) tests = new List<object>();
        int i = 0;
        foreach (object o in tests)
        {
            var t = o as IDictionary<string, object>;
            if (t == null) continue;
            string code = Dpub.S(t, "code");
            string mesure = "", resultat = "";
            bool done = fait.Contains(code);
            foreach (object orr in Json.L(res, "tests"))
            {
                var r2 = orr as IDictionary<string, object>;
                if (r2 != null && Dpub.S(r2, "test") == code)
                { mesure = Dpub.S(r2, "mesure"); resultat = Dpub.S(r2, "resultat"); break; }
            }
            rows.Add(new GRow(code, new[] { Convert.ToString(i + 1), e2.S("id"), code, "T", "I", done ? "Oui" : "Non",
                                            mesure, resultat }, !done));
            i++;
        }
        g.Fill(rows);
        if (tests.Count == 0)
            U.Info(this, "Aucun test associ\u00E9 \u00E0 cette r\u00E9f\u00E9rence.\nParam\u00E9trez-les dans \u00AB Param Tests Labo \u00BB.");
    }

    void Enregistrer()
    {
        if (e == null) { U.Warn(this, "Affichez d'abord une \u00E9tiquette."); return; }
        string te = V["te"].Text.Trim().ToUpper();
        if (te == "") { U.Warn(this, "Indiquez le code test (colonne Test)."); return; }
        DictO res = S.LaboRes(e.S("id"));
        if (res == null) res = new Dictionary<string, object>();
        var tests = new List<object>();
        foreach (object o in Json.L(res, "tests"))
        {
            var t = o as IDictionary<string, object>;
            if (t != null && Dpub.S(t, "test") != te) tests.Add(t);
        }
        tests.Add(new Dictionary<string, object> {
            { "test", te }, { "mesure", V["me"].Text }, { "observation", V["ob"].Text },
            { "min", U.Num(V["mn"].Text) }, { "max", U.Num(V["mx"].Text) },
            { "resultat", V["re"].Text }, { "annule", ann.Checked }, { "date", date.Text } });
        res["tests"] = tests;
        S.LaboResSet(e.S("id"), res);
        DictO p = S.LaboParam(e.S("rf"), null);
        if (p == null) p = new Dictionary<string, object>();
        var fait = new HashSet<string>();
        foreach (object o in tests)
        {
            var t = o as IDictionary<string, object>;
            if (t != null && !(t.ContainsKey("annule") && (t["annule"] is bool && (bool)t["annule"]))) fait.Add(Dpub.S(t, "test"));
        }
        var requis = new HashSet<string>();
        foreach (object o in Json.L(p, "tests"))
        {
            var t = o as IDictionary<string, object>;
            if (t != null) requis.Add(Dpub.S(t, "code"));
        }
        bool allDone = requis.Count > 0;
        foreach (string req in requis) if (!fait.Contains(req)) { allDone = false; break; }
        if ((e.S("st") == "LABOET" || e.S("st") == "RECEP") && requis.Count > 0 && allDone)
        {
            S.SetLabo(e.S("id"), "LABOFT");
            S.Log("Labo : \u00E9tiquette " + e.S("id") + " pass\u00E9e en LABO FT automatiquement (" + fait.Count + " test(s) enregistr\u00E9(s))");
            U.Info(this, "\u00C9tiquette " + e.S("id") + " : tous les tests sont enregistr\u00E9s.\n" +
                         "Elle est pass\u00E9e automatiquement en LABO FT " +
                         "(visible dans Consultation des stocks, colonne Labo FT).");
        }
        else
        {
            U.Info(this, "R\u00E9sultat enregistr\u00E9.");
        }
        Chercher();
    }

    void Imprimer()
    {
        if (e == null) { U.Warn(this, "Affichez d'abord une \u00E9tiquette."); return; }
        try
        {
            byte[] data = System.Text.Encoding.UTF8.GetBytes(U.ZplPiplette(e, S));
            if (S.Cfg("zip") != null && S.Cfg("zip") != "")
                U.SendNet(data, S.Cfg("zip"), S.Cfg("zport", "9100"));
            else
            {
                double tmo = U.Num(S.Cfg("tmo", "100")) / 1000.0;
                if (tmo == 0) tmo = 0.1;
                U.SendSerial(data, S.Cfg("com", "COM1"), S.Cfg("baud", "9600"), S.Cfg("bits", "8"),
                             S.Cfg("stop", "1"), S.Cfg("par", "Sans"), S.Cfg("dtr", "1"), tmo, S.Cfg("buf", "5000"));
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "Impression impossible : " + ex.Message, C.APP, MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        U.Info(this, "Piplette envoy\u00E9e \u00E0 la Zebra.");
    }
}
}

// ===== part08b_listes.cs =====
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 M.A.J Liste \u00E0 servir / \u00C9dition des stocks secondaires \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;

// \u2500\u2500 Fen\u00EAtres n\u00B01/2/3 : M.A.J Liste \u00E0 servir \u2500\u2500
public class MAJListe : Win
{
    TextBox vt, vof, ven;
    Grid g1, g2;

    public MAJListe(App app) : base(app, "M.A.J Liste \u00E0 servir", "1150x640")
    {
        vt = UI.Ent(10); vof = UI.Ent(16); ven = UI.Ent(16);

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 10;
        for (int i = 0; i < 10; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        new CodeField(top, App, "client", "Tiers", vt, 0, 10);
        top.Controls.Add(UI.Lab(null, "Recherche N\u00B0 OF :"), 4, 0);
        top.Controls.Add(vof, 5, 0);
        top.Controls.Add(UI.Lab(null, "Recherche N\u00B0 ENVOI :"), 6, 0);
        top.Controls.Add(ven, 7, 0);
        top.Controls.Add(UI.Btn("Afficher \uD83D\uDD0D", delegate { Afficher(); }, false, 12), 8, 0);

        var lab1 = UI.Lab(null, "Ent\u00EAte Liste \u00E0 Servir");
        g1 = new Grid(null, new[] { "N\u00B0 Envoi", "Date", "Observation", "Atelier", "Etat" },
                      new[] { 150, 110, 300, 130, 80 }, 3, null, null, null);
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Top; bar.Height = 36; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Ajouter une R\u00E9f/Col \u2795", delegate { Ajouter(); }, false, 16));
        bar.Controls.Add(UI.Btn("Supprimer une R\u00E9f/Col \uD83D\uDDD1", delegate { Supprimer(); }, true, 16));
        bar.Controls.Add(UI.Btn("Remettre \u00E0 l'\u00E9tat D \uD83D\uDD04", delegate { Reset(); }, false, 16));
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));
        var lab2 = UI.Lab(null, "Lignes Liste \u00E0 Servir");
        g2 = new Grid(null, new[] { "Ligne", "Code R\u00E9f\u00E9rence", "Coloris", "Besoin Th\u00E9orique", "Besoin R\u00E9el",
                                    "Observation", "Type Affectation" },
                      new[] { 70, 160, 90, 120, 110, 220, 120 }, 10, null, null, new[] { 3, 4 });
        g2.Dock = DockStyle.Fill;

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g1, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, 3);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab2, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g2, 0, 5);
    }

    List<KeyValuePair<Row, DictO>> Ofs()
    {
        string of = vof.Text.Trim().ToUpper(), en = ven.Text.Trim();
        var output = new List<KeyValuePair<Row, DictO>>();
        foreach (Row c in S.Cmds())
        {
            DictO d = S.OfdGet(c.S("n"));
            if (d == null) d = new Dictionary<string, object>();
            if (of != "" && c.S("n").StartsWith(of))
                output.Add(new KeyValuePair<Row, DictO>(c, d));
            else if (en != "" && (Dg2.S(d, "envoi") == en || Dg2.S(d, "regroup") == en))
                output.Add(new KeyValuePair<Row, DictO>(c, d));
        }
        return output;
    }

    string LasKey()
    {
        return "las:" + (vof.Text.Trim().ToUpper() != "" ? vof.Text.Trim().ToUpper() : ven.Text.Trim());
    }

    Dictionary<string, object> Modifs()
    {
        Dictionary<string, object> m;
        object parsed = null;
        try { parsed = Json.Parse(S.Cfg(LasKey()) ?? "null"); }
        catch { }
        m = parsed as Dictionary<string, object>;
        if (m == null) m = new Dictionary<string, object>();
        if (!m.ContainsKey("ajout")) m["ajout"] = new List<object>();
        if (!m.ContainsKey("suppr")) m["suppr"] = new List<object>();
        return m;
    }

    void Afficher()
    {
        var ofs = Ofs();
        if (ofs.Count == 0) { U.Warn(this, "Aucun OF trouv\u00E9 pour ce tiers / ce N\u00B0 d'envoi."); return; }
        var r1 = new List<GRow>();
        foreach (KeyValuePair<Row, DictO> kv in ofs)
        {
            Row c = kv.Key; DictO d = kv.Value;
            string envoi = d.ContainsKey("envoi") && Dg2.S(d, "envoi") != "" ? Dg2.S(d, "envoi")
                             : (d.ContainsKey("regroup") && Dg2.S(d, "regroup") != "" ? Dg2.S(d, "regroup") : "-");
            r1.Add(new GRow(c.S("n"), new[] { envoi, c.S("d"), Dg2.S(d, "commentaire"), Dg2.S(d, "atelier"), "D" }, false));
        }
        g1.Fill(r1);

        var m = Modifs();
        var rows = new List<GRow>(); int n = 0;
        var suppr = new HashSet<string>();
        foreach (object o in Json.L(m, "suppr")) if (o != null) suppr.Add(o.ToString());
        foreach (KeyValuePair<Row, DictO> kv in ofs)
        {
            Row c = kv.Key;
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", c.S("n")))
            {
                n++;
                if (suppr.Contains(l.S("rf") + "|" + l.S("co"))) continue;
                rows.Add(new GRow(l.S("rf") + "|" + l.S("co"),
                    new[] { Convert.ToString(n), l.S("rf"), l.S("co"), U.F3(l.D("q")), U.F3(l.D("q") - l.D("p")),
                            "", "D" }, l.D("q") - l.D("p") > 0.0005));
            }
        }
        foreach (object o in Json.L(m, "ajout"))
        {
            var a = o as IDictionary<string, object>;
            if (a == null) continue;
            n++;
            rows.Add(new GRow("+" + Dg2.S(a, "rf") + "|" + Dg2.S(a, "co"),
                new[] { Convert.ToString(n), Dg2.S(a, "rf"), Dg2.S(a, "co"),
                        U.F3(a.ContainsKey("q") ? U.Num(a["q"]) : 0), U.F3(a.ContainsKey("q") ? U.Num(a["q"]) : 0),
                        Dg2.S(a, "obs"), "C" }, false));
        }
        g2.Fill(rows);
    }

    void Ajouter()
    {
        var w = new Form();
        w.Text = "Choix R\u00E9f\u00E9rence / Coloris"; w.BackColor = Color.White;
        w.ClientSize = new Size(340, 220); w.StartPosition = FormStartPosition.CenterParent;
        var tlp = new TableLayoutPanel(); tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 2;
        var vrf = UI.Ent(16); var vco = UI.Ent(16); var vq = UI.Ent(16);
        tlp.Controls.Add(UI.Lab(null, "R\u00E9f\u00E9rence :"), 0, 0); tlp.Controls.Add(vrf, 1, 0);
        tlp.Controls.Add(UI.Lab(null, "Coloris :"), 0, 1); tlp.Controls.Add(vco, 1, 1);
        tlp.Controls.Add(UI.Lab(null, "Quantit\u00E9 :"), 0, 2); tlp.Controls.Add(vq, 1, 2);
        var fr = new TableLayoutPanel(); fr.BackColor = Color.White;
        var bok = UI.Btn("Valider \u2714", delegate
        {
            if (vrf.Text.Trim() == "") { U.Warn(w, "Saisissez la r\u00E9f\u00E9rence."); return; }
            var m = Modifs();
            var ajout = Json.L(m, "ajout");
            ajout.Add(new Dictionary<string, object> { { "rf", vrf.Text.Trim().ToUpper() },
                                                       { "co", vco.Text.Trim().ToUpper() },
                                                       { "q", U.Num(vq.Text) }, { "obs", "" } });
            m["ajout"] = ajout;
            S.SetCfg(LasKey(), Json.Dump(m));
            S.Log("Liste \u00E0 servir : r\u00E9f\u00E9rence " + vrf.Text + " / " + vco.Text + " ajout\u00E9e");
            w.Close();
            Afficher();
        }, false, 12);
        var bquit = UI.Btn("Quitter \u2715", delegate { w.Close(); }, true, 12);
        fr.Controls.Add(bok); fr.Controls.Add(bquit);
        tlp.Controls.Add(fr, 0, 3); tlp.SetColumnSpan(fr, 2);
        w.Controls.Add(tlp);
        w.ShowDialog(this);
    }

    void Supprimer()
    {
        if (g2.Cur == null || g2.Cur == "") { U.Warn(this, "S\u00E9lectionnez une ligne R\u00E9f/Col."); return; }
        string cur = g2.Cur;
        var m = Modifs();
        if (cur.StartsWith("+"))
        {
            string rc = cur.Substring(1);
            int p = rc.IndexOf('|');
            string rf = p >= 0 ? rc.Substring(0, p) : rc;
            string co = p >= 0 ? rc.Substring(p + 1) : "";
            var keep = new List<object>();
            foreach (object o in Json.L(m, "ajout"))
            {
                var a = o as IDictionary<string, object>;
                if (a == null || Dg2.S(a, "rf") + "|" + Dg2.S(a, "co") != rf + "|" + co) keep.Add(o);
            }
            m["ajout"] = keep;
        }
        else
        {
            var suppr = Json.L(m, "suppr");
            suppr.Add(cur);
            m["suppr"] = suppr;
        }
        S.SetCfg(LasKey(), Json.Dump(m));
        S.Log("Liste \u00E0 servir : ligne " + cur + " supprim\u00E9e");
        Afficher();
    }

    void Reset()
    {
        S.SetCfg(LasKey(), "");
        S.Log("Liste \u00E0 servir " + LasKey() + " remise \u00E0 l'\u00E9tat D");
        Afficher();
    }
}

static class Dg2
{
    public static string S(IDictionary<string, object> d, string k)
    {
        return d != null && d.ContainsKey(k) && d[k] != null ? Convert.ToString(d[k]) : "";
    }
    public static double N(IDictionary<string, object> d, string k)
    {
        return d != null && d.ContainsKey(k) && d[k] != null ? U.Num(d[k]) : 0;
    }
}

// \u2500\u2500 Fen\u00EAtre n\u00B05 : \u00C9dition des stocks secondaires \u2500\u2500
public class StockSec : Win
{
    TextBox vt;
    Dictionary<string, CheckBox> F;
    CheckBox tc;
    ComboBox tp;
    Grid g;
    List<GRow> rows;

    public StockSec(App app) : base(app, "\u00C9dition des stocks secondaires", "1150x620")
    {
        vt = UI.Ent(10);
        F = new Dictionary<string, CheckBox>();
        F["f"] = UI.Check("Fournitures"); F["g"] = UI.Check("Galon et bande"); F["m"] = UI.Check("Mati\u00E8res");
        foreach (var c in F.Values) c.Checked = true;

        TableLayoutPanel tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new TableLayoutPanel(); top.Dock = DockStyle.Top; top.Height = 34; top.BackColor = Color.White;
        top.ColumnCount = 3;
        for (int i = 0; i < 3; i++) top.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        new CodeField(top, App, "client", "Tiers", vt, 0, 10);

        var fl = UI.Frame("Filtre"); fl.Height = 110; fl.Dock = DockStyle.Top;
        var flfl = new FlowLayoutPanel(); flfl.Dock = DockStyle.Fill; flfl.BackColor = Color.White;
        foreach (var t in new[] { new[] { "f", "" }, new[] { "g", "" }, new[] { "m", "" } })
            flfl.Controls.Add(F[t[0]]);
        var tr = new FlowLayoutPanel(); tr.BackColor = Color.White; tr.WrapContents = false;
        tc = UI.Check("Tri : Coloris");
        tr.Controls.Add(tc);
        tr.Controls.Add(UI.Lab(null, "Type Stock :"));
        tp = UI.Combo("Tous", "Surplus", "Stock secondaire");
        tr.Controls.Add(tp);
        flfl.Controls.Add(tr);
        fl.Controls.Add(flfl);

        var b = new FlowLayoutPanel(); b.Dock = DockStyle.Top; b.Height = 36; b.BackColor = Color.White; b.WrapContents = false;
        b.Controls.Add(UI.Btn("Afficher \uD83D\uDD0D", delegate { Afficher(); }, false, 12));
        b.Controls.Add(UI.Btn("Imprimer \uD83D\uDDA8", delegate { Imprimer(); }, false, 12));
        b.Controls.Add(UI.Btn("Export Excel \uD83D\uDCCA", delegate { Export(); }, false, 14));
        b.Controls.Add(UI.Btn("Tout s\u00E9lectionner \u2611", delegate { ToutSel(); }, false, 14));
        b.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        g = new Grid(null, new[] { "Sel.", "R\u00E9f\u00E9rence", "Coloris", "Type", "Libell\u00E9", "Surplus",
                                   "Stock Secondaire", "Dispo" },
                     new[] { 50, 150, 90, 110, 220, 100, 130, 100 }, 12, null, null, new[] { 5, 6, 7 });
        g.Dock = DockStyle.Fill;
        rows = new List<GRow>();

        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, 0);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(fl, 0, 1);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(b, 0, 2);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, 3);
    }

    void Afficher()
    {
        string t = vt.Text.Trim().ToUpper();
        var rws = new List<GRow>();
        foreach (Row r in S.Q("SELECT DISTINCT rf, co, ty FROM eti ORDER BY rf, co"))
        {
            string rf = r.S("rf"), co = r.S("co"), ty = r.S("ty");
            double sur = S.Surplus(rf, co), sec = S.Secondaire(rf, co);
            if (sur <= 0.0005 && sec <= 0.0005) continue;
            if (ty == "Mati\u00E8re" && !F["m"].Checked) continue;
            if (ty == "Galon et bande" && !F["g"].Checked) continue;
            if (ty == "Fournitures" && !F["f"].Checked) continue;
            string tpv = (string)tp.SelectedItem;
            if (tpv == "Surplus" && sur <= 0.0005) continue;
            if (tpv == "Stock secondaire" && sec <= 0.0005) continue;
            rws.Add(new GRow(rf + "|" + co, new[] { "\u2611", rf, co, ty, S.Lib("reference", rf) ?? rf,
                                                    U.F3(sur), U.F3(sec), U.F3(S.Logique(rf, co) - S.Reserved(rf, co)) }, false));
        }
        if (tc.Checked)
            rws = rws.OrderBy(x => x.V[2]).ThenBy(x => x.V[1]).ToList();
        rows = rws;
        g.Fill(rows);
    }

    void ToutSel()
    {
        U.Info(this, rows.Count + " ligne(s) s\u00E9lectionn\u00E9e(s).");
    }

    void Imprimer()
    {
        var tr = new StringBuilder();
        foreach (GRow r in rows)
        {
            tr.Append("<tr>");
            for (int i = 1; i < r.V.Length; i++)
                tr.Append("<td>").Append(U.Esc(r.V[i])).Append("</td>");
            tr.Append("</tr>");
        }
        U.OpenHtml("<h3>\u00C9dition des stocks secondaires</h3>" +
                   "<table><tr><th>R\u00E9f\u00E9rence</th><th>Coloris</th><th>Type</th><th>Libell\u00E9</th>" +
                   "<th>Surplus</th><th>Stock Secondaire</th><th>Dispo</th></tr>" + tr + "</table>");
    }

    void Export()
    {
        var fd = new SaveFileDialog();
        fd.FileName = "stocks-secondaires.csv";
        fd.Filter = "CSV / Excel|*.csv";
        if (fd.ShowDialog(this) != DialogResult.OK) return;
        string p = fd.FileName;
        var data = new List<string[]>();
        foreach (GRow r in rows)
        {
            var v = new List<string>();
            for (int i = 1; i < r.V.Length; i++) v.Add(r.V[i]);
            data.Add(v.ToArray());
        }
        Csv.Write(p, new[] { "R\u00E9f\u00E9rence", "Coloris", "Type", "Libell\u00E9", "Surplus", "Stock Secondaire", "Dispo" }, data);
        try { System.Diagnostics.Process.Start(p); } catch { }
    }
}
}

// ===== part09_flot.cs =====
// \u2500\u2500\u2500 Portail Internet (PC \u2194 mobile par Wi-Fi local) + Sortie mati\u00E8re OF + Fabrication L + Transfert \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictO2 = System.Collections.Generic.Dictionary<string, object>;

public static class PortalConstantes
{
    public const string HTML = "<!DOCTYPE html>\n"
        + "<html lang=\"fr\"><head><meta charset=\"utf-8\">\n"
        + "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
        + "<title>Pro Textile Syst\u00E8me \u2013 Mobile</title>\n"
        + "<style>\n"
        + "body{font-family:Segoe UI,Arial;background:#1b2a7a;color:#fff;margin:0;padding:14px}\n"
        + "h1{text-align:center;font-size:19px;padding:10px;border-bottom:2px solid #e8a020}\n"
        + ".menu{display:flex;flex-direction:column;gap:12px;max-width:420px;margin:14px auto}\n"
        + ".menu button{background:#2f6fb2;color:#fff;border:0;border-radius:10px;padding:16px;font-size:17px;\n"
        + " font-weight:bold;text-align:left;display:flex;align-items:center;gap:12px}\n"
        + ".menu button:active{background:#1b4e80}\n"
        + ".screen{background:#eef1f8;color:#1b2a3a;border-radius:10px;padding:10px;display:none}\n"
        + ".ligne{background:#fff;border:1px solid #ccc;border-radius:8px;padding:10px;margin:8px 0;color:#1b2a3a}\n"
        + "input{width:100%;box-sizing:border-box;padding:8px;margin:3px 0;border:1px solid #bbb;border-radius:6px;font-size:15px}\n"
        + ".btn2{width:100%;padding:14px;background:#2f6fb2;color:#fff;border:0;border-radius:8px;font-size:16px;font-weight:bold;margin-top:8px}\n"
        + ".btnr{background:#b23f3f}\n"
        + "#msg{padding:10px;border-radius:6px;margin:8px 0;display:none;color:#1b2a3a}\n"
        + ".ok{background:#d8f5dd}.ko{background:#f9cdcd}\n"
        + "</style></head><body>\n"
        + "<h1>\uD83E\uDDF5 PRO TEXTILE SYSTEME 1</h1>\n"
        + "<div id=\"msg\"></div>\n"
        + "<div class=\"menu\" id=\"menu\">\n"
        + "<button onclick=\"open('empl')\">\u2B07 CHARGEMENT EMPL.</button>\n"
        + "<button onclick=\"open('fourn')\">\u2194 PICKING FOUR./DENT.</button>\n"
        + "<button onclick=\"open('matiere')\">\uD83D\uDCE6 SORTIE MATIERE</button>\n"
        + "<button onclick=\"open('rentree')\">\uD83D\uDD04 RE-ENTREE</button>\n"
        + "<button onclick=\"open('annul')\">\uD83D\uDDD1 ANNULATION</button>\n"
        + "<button onclick=\"decharger()\">\uD83D\uDEBA DECHARGEMENT</button>\n"
        + "<button onclick=\"quitter()\">\u2715 QUITTER</button>\n"
        + "</div>\n"
        + "<div class=\"screen\" id=\"scr\">\n"
        + "<div style=\"text-align:right\"><a href=\"#\" onclick=\"retour()\" style=\"color:#2f6fb2;font-weight:bold\">\u2190 RETOUR MENU</a></div>\n"
        + "<div id=\"liste\"></div>\n"
        + "<button class=\"btn2\" id=\"valid\" onclick=\"envoyer()\">\u2714 VALIDER LES LIGNES SAISIES</button>\n"
        + "</div>\n"
        + "<script>\n"
        + "const t = new URLSearchParams(location.search).get('t') || '';\n"
        + "let key = 'fourn';\n"
        + "const msg = document.getElementById('msg');\n"
        + "function aff(m, ok){ msg.style.display='block'; msg.className=ok?'ok':'ko'; msg.textContent=m; }\n"
        + "function retour(){ document.getElementById('menu').style.display='flex';\n"
        + "  document.getElementById('scr').style.display='none'; msg.style.display='none'; }\n"
        + "function open(k){\n"
        + "  key = k;\n"
        + "  if(k==='rentree' || k==='annul'){\n"
        + "    document.getElementById('menu').style.display='none';\n"
        + "    document.getElementById('scr').style.display='block';\n"
        + "    const lbl = k==='rentree' ? 'RE-ENTREE : scannez l\u2019\u00E9tiquette et la quantit\u00E9 remise en stock'\n"
        + "                               : 'ANNULATION : scannez l\u2019\u00E9tiquette \u00E0 annuler';\n"
        + "    document.getElementById('liste').innerHTML =\n"
        + "      '<div class=\"ligne\"><b>'+lbl+'</b><input id=\"sc\" placeholder=\"\u00C9tiquette (scan ou saisie)\">'+\n"
        + "      '<input id=\"sq\" placeholder=\"Quantit\u00E9\" type=\"number\" step=\"0.001\"></div>';\n"
        + "    return;\n"
        + "  }\n"
        + "  charger();\n"
        + "}\n"
        + "async function charger(){\n"
        + "  try{\n"
        + "    const r = await fetch('/api/picking?t='+encodeURIComponent(t)+'&k='+(key==='empl'?'matiere':key));\n"
        + "    if(!r.ok){ const e = await r.json(); aff(e.error || 'PC injoignable', false); return; }\n"
        + "    const d = await r.json();\n"
        + "    const titres = {empl:'CHARGEMENT EMPLACEMENTS', fourn:'PICKING FOURNITURES / DENTELLE', matiere:'SORTIE MATIERE'};\n"
        + "    document.getElementById('menu').style.display='none';\n"
        + "    document.getElementById('scr').style.display='block';\n"
        + "    let h = '<p><b>'+titres[key]+'</b> \u2014 '+(d.lancement||d.type||'-')+\n"
        + "            ' \u2014 Atelier : '+(d.atelier||'-')+'</p>';\n"
        + "    (d.lignes||[]).forEach((l,i)=>{\n"
        + "      const emp = key==='empl';\n"
        + "      h += '<div class=\"ligne\"><b>'+l.of+' \u2014 '+l.rf+' / '+l.co+'</b><br>Besoin : '+l.besoin+\n"
        + "           ' | Sorti : '+l.sorti+' | Reste : '+l.reste+\n"
        + "           (emp ? '<input id=\"em'+i+'\" placeholder=\"Emplacement\">'\n"
        + "                : '<input id=\"et'+i+'\" placeholder=\"\u00C9tiquette (scan ou saisie)\">')+\n"
        + "           (emp ? '' : '<input id=\"em'+i+'\" placeholder=\"Emplacement\">')+\n"
        + "           '<input id=\"q'+i+'\" placeholder=\"Quantit\u00E9\" type=\"number\" step=\"0.001\"></div>';\n"
        + "    });\n"
        + "    if(!(d.lignes||[]).length) h += '<p>Aucune ligne : pr\u00E9parez le picking sur le PC (\u00AB Charger le portable \uD83D\uDCF1 \u00BB).</p>';\n"
        + "    document.getElementById('liste').innerHTML = h;\n"
        + "  }catch(e){ aff('PC injoignable \u2014 v\u00E9rifiez le m\u00EAme Wi-Fi et le QR.', false); }\n"
        + "}\n"
        + "async function envoyer(){\n"
        + "  const lignes = document.querySelectorAll('.ligne'); const sorties = [];\n"
        + "  lignes.forEach((el,i)=>{\n"
        + "    const et = document.getElementById('et'+i), em = document.getElementById('em'+i);\n"
        + "    const etq = et ? et.value.trim() : '';\n"
        + "    if(!etq && !(em && em.value.trim())) return;\n"
        + "    const b = el.querySelector('b').textContent;\n"
        + "    sorties.push({mode: key,\n"
        + "      of: b.split(' \u2014 ')[0].trim(), rf: b.split(' \u2014 ')[1].split(' / ')[0].trim(),\n"
        + "      co: b.split(' / ')[1].trim(), etiquette: etq || '-',\n"
        + "      emplacement: em ? em.value.trim() : '', qte: document.getElementById('q'+i).value});\n"
        + "  });\n"
        + "  if(!sorties.length){ aff('Aucune ligne saisie.', false); return; }\n"
        + "  try{\n"
        + "    const r = await fetch('/api/retour',{method:'POST',headers:{'Content-Type':'application/json'},\n"
        + "      body:JSON.stringify({token:t, sorties})});\n"
        + "    const d = await r.json();\n"
        + "    aff(d.ok+' ligne(s) transf\u00E9r\u00E9e(s) dans la base du PC \u2714', true);\n"
        + "    retour();\n"
        + "  }catch(e){ aff('Envoi impossible \u2014 PC injoignable.', false); }\n"
        + "}\n"
        + "async function decharger(){ aff('D\u00E9chargement : validez d\u2019abord vos lignes, elles arrivent automatiquement sur le PC.', true); }\n"
        + "function quitter(){ aff('Au revoir \u2014 d\u00E9connectez le Wi-Fi si n\u00E9cessaire.', true); }\n"
        + "</script></body></html>";
}

// \u2500\u2500\u2500 Mini-serveur HTTP sur le PC : sert l'app mobile et \u00E9change les pickings \u2500\u2500\u2500
public class PortalServer
{
    public Store S; public int Port; public string Token;
    Dictionary<string, DictO> picking;
    HttpListener httpd;

    public static PortalServer Current;   // \u00E9quivalent du global PORTAL (None => null)

    public PortalServer(Store S) : this(S, 8765) { }
    public PortalServer(Store S, int port)
    {
        this.S = S; Port = port; Token = S.Token();
        picking = new Dictionary<string, DictO>();
        picking["fourn"] = null; picking["matiere"] = null; picking["empl"] = null;
    }

    public string Ip()
    {
        try
        {
            using (var s = new System.Net.Sockets.Socket(System.Net.Sockets.AddressFamily.InterNetwork,
                   System.Net.Sockets.SocketType.Dgram, System.Net.Sockets.ProtocolType.Udp))
            {
                s.Connect(IPAddress.Parse("8.8.8.8"), 80);
                return (s.LocalEndPoint as System.Net.IPEndPoint).Address.ToString();
            }
        }
        catch
        {
            try { return Dns.GetHostEntry(Dns.GetHostName()).AddressList
                       .First(a => a.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork).ToString(); }
            catch { return "127.0.0.1"; }
        }
    }

    public string Url() { return "http://" + Ip() + ":" + Port + "/?t=" + Token; }

    public void SetPicking(string key, DictO data) { picking[key] = data; }

    public int Integrate(DictO data)
    {
        if (data == null || Dg.S(data, "token") != Token) return 0;
        int ok = 0;
        Dictionary<string, string> seen = new Dictionary<string, string>();
        foreach (var e in DQuick(data))
        {
            try
            {
                S.PickOut(Dg.S(e, "of").ToUpperInvariant(), Dg.S(e, "rf").ToUpperInvariant(),
                          Dg.S(e, "co").ToUpperInvariant(), Dg.S(e, "etiquette"), Dg.S(e, "emplacement"));
                ok++;
            }
            catch (ValueError) { }
        }
        return ok;
    }

    static List<DictO> DQuick(DictO data)
    {
        var out1 = new List<DictO>();
        if (data.ContainsKey("sorties") && data["sorties"] is List<object>)
            foreach (object o in (List<object>)data["sorties"])
                if (o is Dictionary<string, object>) out1.Add((DictO)o);
        return out1;
    }

    public void Start()
    {
        httpd = new HttpListener();
        try { httpd.Prefixes.Add("http://+:" + Port + "/"); httpd.Start(); }
        catch
        {
            httpd.Close();
            httpd = new HttpListener();
            httpd.Prefixes.Add("http://localhost:" + Port + "/");
            httpd.Start();
        }
        var th = new Thread(Serve);
        th.IsBackground = true;
        th.Start();
    }

    void Serve()
    {
        while (true)
        {
            HttpListenerContext ctx;
            try { ctx = httpd.GetContext(); }
            catch { return; }
            HttpListenerContext c = ctx;
            var t = new Thread(delegate() { try { Handle(c); } catch { } });
            t.IsBackground = true;
            t.Start();
        }
    }

    static Dictionary<string, string> Query(string raw)
    {
        var d = new Dictionary<string, string>();
        string q = raw;
        if (q.StartsWith("?")) q = q.Substring(1);
        foreach (string kv in q.Split('&'))
        {
            if (kv.Length == 0) continue;
            int eq = kv.IndexOf('=');
            if (eq < 0) d[Uri.UnescapeDataString(kv)] = "";
            else d[Uri.UnescapeDataString(kv.Substring(0, eq))] = Uri.UnescapeDataString(kv.Substring(eq + 1));
        }
        return d;
    }

    void Send(HttpListenerResponse r, byte[] b, string ctype, int code)
    {
        r.StatusCode = code;
        r.ContentType = ctype;
        r.ContentLength64 = b.Length;
        r.Headers["Access-Control-Allow-Origin"] = "*";
        r.OutputStream.Write(b, 0, b.Length);
        r.OutputStream.Close();
    }

    void SendJson(HttpListenerResponse r, object o, int code)
    {
        Send(r, Encoding.UTF8.GetBytes(Json.Dump(o)), "application/json; charset=utf-8", code);
    }

    void Handle(HttpListenerContext ctx)
    {
        var req = ctx.Request; var res = ctx.Response;
        string path = req.Url.AbsolutePath;
        if (req.HttpMethod == "OPTIONS")
        {
            res.StatusCode = 200;
            res.Headers["Access-Control-Allow-Origin"] = "*";
            res.Headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS";
            res.Headers["Access-Control-Allow-Headers"] = "*";
            res.OutputStream.Close();
            return;
        }
        if (req.HttpMethod == "GET" && (path == "/" || path == "/app" || path == "/index.html"))
        {
            Send(res, Encoding.UTF8.GetBytes(PortalConstantes.HTML), "text/html; charset=utf-8", 200);
            return;
        }
        if (req.HttpMethod == "GET" && path == "/api/picking")
        {
            Dictionary<string, string> qs = Query(req.Url.Query);
            string key = qs.ContainsKey("k") ? qs["k"] : "fourn";
            DictO d = null;
            bool has = key != null && picking.TryGetValue(key, out d) && d != null;
            if (has) SendJson(res, d, 200);
            else
            {
                var err = new DictO2();
                err["error"] = "Aucun picking en cours"; err["key"] = key;
                SendJson(res, err, 404);
            }
            return;
        }
        if (req.HttpMethod == "POST" && path == "/api/retour")
        {
            DictO data;
            try
            {
                long len = req.ContentLength64;
                byte[] buf = new byte[len];
                int done = 0;
                while (done < len) done += req.InputStream.Read(buf, done, (int)(len - done));
                data = (DictO)Json.Parse(Encoding.UTF8.GetString(buf));
            }
            catch
            {
                var err = new DictO2();
                err["ok"] = 0; err["error"] = "JSON invalide";
                SendJson(res, err, 400);
                return;
            }
            var okd = new DictO2();
            okd["ok"] = Integrate(data);
            SendJson(res, okd, 200);
            return;
        }
        var nf = new DictO2();
        nf["error"] = "not found";
        SendJson(res, nf, 404);
    }
}

// \u2500\u2500\u2500 Connexion portable : affiche le code de pairage Pro Textile Syst\u00E8me \u2500\u2500\u2500
public class PairDlg : Win
{
    public PairDlg(App app, string code, string info) : base(app, "Connexion portable \u2013 QR", "440x500")
    {
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1; tlp.RowCount = 5;
        Body.Controls.Add(tlp);
        var lab1 = UI.Lab(null, "Scannez ce code QR avec l\u2019application mobile\nde Pro Textile Syst\u00E8me :");
        lab1.TextAlign = ContentAlignment.MiddleCenter; lab1.Dock = DockStyle.Top;
        tlp.Controls.Add(lab1, 0, 0);
        var box = new Label();
        box.Text = code; box.Font = new Font("Courier New", 9, FontStyle.Bold);
        box.BackColor = Color.White; box.BorderStyle = BorderStyle.FixedSingle;
        box.TextAlign = ContentAlignment.MiddleCenter; box.Anchor = AnchorStyles.None;
        box.AutoSize = true; box.MaximumSize = new Size(380, 0);
        tlp.Controls.Add(box, 0, 1);
        var hint = UI.Lab(null, "(QR graphique indisponible \u2014 utilisez le code ci-dessus)");
        hint.TextAlign = ContentAlignment.MiddleCenter; hint.Dock = DockStyle.Top;
        tlp.Controls.Add(hint, 0, 2);
        var lab2 = UI.Lab(null, info);
        lab2.TextAlign = ContentAlignment.MiddleCenter; lab2.Anchor = AnchorStyles.None; lab2.AutoSize = true;
        lab2.MaximumSize = new Size(380, 0);
        tlp.Controls.Add(lab2, 0, 3);
        var bar = new FlowLayoutPanel(); bar.FlowDirection = FlowDirection.TopDown; bar.BackColor = Color.White;
        bar.AutoSize = true; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Quitter \u21E5", delegate { Close(); }, true, 12));
        tlp.Controls.Add(bar, 0, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 55));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 45));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
    }
}
}

// ===== part09b_flot.cs =====
// \u2500\u2500\u2500 Fen\u00EAtre 1 : Sortie mati\u00E8re OF \u2500\u2500 liste des lancements cr\u00E9\u00E9s/valid\u00E9s \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictO2 = System.Collections.Generic.Dictionary<string, object>;

public class SortieOF : Win
{
    Grid g, go;
    TextBox obs;

    public SortieOF(App app) : base(app, "Sortie mati\u00E8re OF", "1050x660")
    {
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Fill; top.Height = 110;
        top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Btn("Sortie mati\u00E8re \u27A1", delegate { OpenMat(); }, false, 18));
        top.Controls.Add(UI.Btn("Rafra\u00EEchir \uD83D\uDD04", delegate { Fill(); }, false, 14));
        top.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        var lg = new GroupBox(); lg.Text = "L\u00E9gende"; lg.Font = C.FONT; lg.AutoSize = true;
        var lgf = new FlowLayoutPanel(); lgf.FlowDirection = FlowDirection.TopDown; lgf.AutoSize = true; lgf.WrapContents = false;
        foreach (var e in new[] {
                     new object[] { Color.FromArgb(0xf9, 0xcd, 0xcd), "A sortir" },
                     new object[] { Color.FromArgb(0xff, 0xff, 0xdf), "A compl\u00E9ter" },
                     new object[] { Color.White, "Complet" },
                     new object[] { Color.FromArgb(0x4c, 0xb8, 0x66), "Regroupement" } })
            lgf.Controls.Add(Swatch((Color)e[0], (string)e[1]));
        lg.Controls.Add(lgf);
        top.Controls.Add(lg);

        var labL = UI.Lab(null, "N\u00B0 LANCEMENT");
        g = new Grid(null, new[] { "Coll", "N\u00B0 L", "Date", "\u00C9tat", "Tiers", "Obs.", "Destination" },
                     new[] { 60, 150, 110, 110, 90, 220, 220 }, 9, Pick, OpenMat, null);
        var labO = UI.Lab(null, "Observation Lancement");
        obs = UI.Text(70, 2);
        var labOf = UI.Lab(null, "Liste des OF associ\u00E9s");
        go = new Grid(null, new[] { "OF", "Code mod\u00E8le", "Indice", "Date" },
                      new[] { 160, 160, 100, 120 }, 5, null, null, null);
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.Height = 40; bar.BackColor = Color.White;
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labL, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labO, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(obs, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(labOf, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(go, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);
        g.Height = 9 * 20 + 26; go.Height = 5 * 20 + 26;

        Fill();
        // IA cach\u00E9e : contr\u00F4le silencieux, n'alerte que s'il y a un risque
        App.ActivateDelayed(delegate { IaControle(); });
    }

    static Control Swatch(Color c, string t)
    {
        var f = new FlowLayoutPanel(); f.AutoSize = true; f.WrapContents = false; f.Margin = new Padding(1);
        var s = new Panel(); s.BackColor = c; s.Width = 22; s.Height = 14;
        s.Margin = new Padding(1); s.BorderStyle = BorderStyle.FixedSingle;
        var l = UI.Lab(null, t); l.Margin = new Padding(4, 2, 2, 2);
        f.Controls.Add(s); f.Controls.Add(l);
        return f;
    }

    void IaControle()
    {
        try
        {
            var am = new AI(S).AlertesManque();
            if (am.Count > 0)
            {
                var sb = new StringBuilder();
                foreach (object[] a in am.Take(8))
                    sb.AppendLine("\u2022 " + a[0] + " / " + a[1] + " : manque " + a[4]);
                U.Warn(this, "\uD83E\uDDE0 Assistant IA \u2014 alerte avant sortie :\n\n" + sb.ToString() +
                       "\n(IA en lecture seule : rien n'a \u00E9t\u00E9 modifi\u00E9.)");
            }
        }
        catch { }
    }

    public void Fill()
    {
        List<DictO> L = S.Lancements();
        var rows = new List<GRow>();
        foreach (DictO r in L)
            rows.Add(new GRow(Dg.S(r, "lancement"),
                new[] { Dg.S(r, "regroup", "-"), Dg.S(r, "lancement"), Dg.S(r, "date"), Dg.S(r, "etat"),
                        Dg.S(r, "tiers", "-"), Dg.S(r, "obs").Length > 30 ? Dg.S(r, "obs").Substring(0, 30) : Dg.S(r, "obs"),
                        Dg.S(r, "dest", "-") },
                Dg.S(r, "etat") == "A sortir"));
        g.Fill(rows);
        Pick(g.Cur);
    }

    void Pick(string cur)
    {
        obs.Text = "";
        var rows = new List<GRow>();
        if (cur != null)
        {
            foreach (DictO r in S.Lancements())
                if (Dg.S(r, "lancement") == cur)
                {
                    obs.Text = Dg.S(r, "obs");
                    rows.Add(new GRow(Dg.S(r, "n"),
                        new[] { Dg.S(r, "n"), Dg.S(r, "modele", "-"), Dg.S(r, "regroup", "-"), Dg.S(r, "date") }, false));
                }
        }
        go.Fill(rows);
    }

    void OpenMat()
    {
        if (g.Cur == null) { U.Warn(this, "Double-cliquez sur le lancement \u00E0 sortir."); return; }
        new SortieMat(App, g.Cur).Show();
    }
}

// \u2500\u2500\u2500 Fen\u00EAtre 2 : Sortie mati\u00E8re d'un lancement + chargement/d\u00E9chargement du portable \u2500\u2500\u2500
public class SortieMat : Win
{
    string lancement;
    TextBox dest, obsv;
    Grid g;

    public SortieMat(App app, string lancement) : base(app, "Sortie mati\u00E8re", "1150x620")
    {
        this.lancement = lancement;
        List<DictO> ofs = new List<DictO>();
        foreach (DictO oo in S.Lancements())
            if (Dg.S(oo, "lancement") == lancement) ofs.Add(oo);

        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Fill; top.Height = 110;
        top.BackColor = Color.White; top.WrapContents = false;
        var lb = new GroupBox(); lb.Text = ""; lb.Font = C.FONT; lb.AutoSize = true;
        var lbt = new TableLayoutPanel(); lbt.AutoSize = true; lbt.ColumnCount = 2;
        lbt.Controls.Add(UI.Lab(null, "Tiers :"), 0, 0);
        var ltiers = new Label(); ltiers.Text = ofs.Count > 0 ? Dg.S(ofs[0], "tiers") : "";
        ltiers.BackColor = Color.FromArgb(0xea, 0xf1, 0xfb); ltiers.BorderStyle = BorderStyle.FixedSingle;
        ltiers.Width = 12 * 7 + 10; ltiers.Font = C.FONT;
        lbt.Controls.Add(ltiers, 1, 0);
        lbt.Controls.Add(UI.Lab(null, "N\u00B0 Lancement :"), 0, 1);
        var llan = new Label(); llan.Text = lancement;
        llan.BackColor = Color.FromArgb(0xea, 0xf1, 0xfb); llan.BorderStyle = BorderStyle.FixedSingle;
        llan.Width = 14 * 7 + 10; llan.Font = C.FONTB;
        lbt.Controls.Add(llan, 1, 1);
        lb.Controls.Add(lbt);
        top.Controls.Add(lb);

        var mid = new FlowLayoutPanel(); mid.FlowDirection = FlowDirection.TopDown;
        mid.AutoSize = true; mid.WrapContents = false;
        mid.Controls.Add(UI.Btn("Charger le portable \uD83D\uDCF1", delegate { Charger(); }, false, 20));
        mid.Controls.Add(UI.Btn("D\u00E9charger picking \u2B07", delegate { Decharger(); }, false, 20));
        mid.Controls.Add(UI.Btn("Imprimer \uD83D\uDDA8", delegate { Imprimer(); }, false, 14));
        mid.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));
        top.Controls.Add(mid);

        var lg = new GroupBox(); lg.Text = "L\u00E9gende"; lg.Font = C.FONT; lg.AutoSize = true;
        var lgf = new FlowLayoutPanel(); lgf.FlowDirection = FlowDirection.TopDown; lgf.AutoSize = true; lgf.WrapContents = false;
        foreach (var e in new[] {
                     new object[] { Color.FromArgb(0xc9, 0xc9, 0xea), "Mati\u00E8re Sortie Totalement" },
                     new object[] { Color.FromArgb(0x4c, 0xb8, 0x66), "Mati\u00E8re pouvant sortir" },
                     new object[] { Color.FromArgb(0xf9, 0xcd, 0xcd), "Manque mati\u00E8re (cause surplus)" },
                     new object[] { Color.FromArgb(0xff, 0x00, 0x00), "Manque mati\u00E8re (stock insuffisant)" } })
            lgf.Controls.Add(SortieOFSwatch((Color)e[0], (string)e[1]));
        lg.Controls.Add(lgf);
        top.Controls.Add(lg);

        var r2 = new FlowLayoutPanel(); r2.Dock = DockStyle.Fill; r2.Height = 34; r2.BackColor = Color.White; r2.WrapContents = false;
        r2.Controls.Add(UI.Lab(null, "Atelier de destination :"));
        dest = UI.Ent(40); dest.Text = ofs.Count > 0 ? Dg.S(ofs[0], "dest") : "";
        r2.Controls.Add(dest);
        r2.Controls.Add(UI.Lab(null, "Observation :"));
        obsv = UI.Ent(40);
        r2.Controls.Add(obsv);

        g = new Grid(null, new[] { "R\u00E9f\u00E9rence", "Coloris", "Besoin Log.", "Log. S\u00E9rie", "Log. Coll.", "Sp\u00E9cial",
                                   "R\u00E9serv\u00E9", "A Sortir", "Sortie" },
                     new[] { 150, 90, 100, 100, 100, 90, 100, 100, 100 }, 12, null, null,
                     new[] { 2, 3, 4, 5, 6, 7, 8 });
        g.Dock = DockStyle.Fill;
        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(r2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); tlp.Controls.Add(g, 0, r++);
        Refresh();
    }

    static Control SortieOFSwatch(Color c, string t)
    {
        var f = new FlowLayoutPanel(); f.AutoSize = true; f.WrapContents = false; f.Margin = new Padding(1);
        var s = new Panel(); s.BackColor = c; s.Width = 22; s.Height = 14;
        s.Margin = new Padding(1); s.BorderStyle = BorderStyle.FixedSingle;
        var l = UI.Lab(null, t); l.Margin = new Padding(4, 2, 2, 2);
        f.Controls.Add(s); f.Controls.Add(l);
        return f;
    }

    List<object[]> Lignes()
    {
        var out1 = new List<object[]>();
        foreach (DictO r in S.Lancements())
        {
            if (Dg.S(r, "lancement") != lancement) continue;
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", Dg.S(r, "n")))
                out1.Add(new object[] { r, l });
        }
        return out1;
    }

    void Refresh()
    {
        var rows = new List<GRow>();
        foreach (object[] pair in Lignes())
        {
            Row l = (Row)pair[1];
            double log = S.Logique(l.S("rf"), l.S("co"));
            double res = S.Reserved(l.S("rf"), l.S("co"));
            double aSortir = Math.Max(0, l.D("q") - l.D("p"));
            rows.Add(new GRow(Dg.S((DictO)pair[0], "n") + "|" + l.S("rf") + "|" + l.S("co"),
                new[] { l.S("rf"), l.S("co"), U.F3(l.D("q")), U.F3(log), U.F3(log - res), "0,000",
                        U.F3(Math.Max(0, l.D("q") - l.D("p"))), U.F3(aSortir), U.F3(l.D("p")) },
                log < aSortir));
        }
        g.Fill(rows);
    }

    void Charger()
    {
        string dir = Path.Combine(U.BaseDir(), "exports", "portable");
        Directory.CreateDirectory(dir);
        var lignes = new List<DictO>();
        foreach (object[] pair in Lignes())
        {
            Row l = (Row)pair[1];
            if (l.D("q") - l.D("p") <= .0005) continue;
            var d = new DictO2();
            d["of"] = Dg.S((DictO)pair[0], "n"); d["rf"] = l.S("rf"); d["co"] = l.S("co");
            d["besoin"] = l.D("q"); d["sorti"] = l.D("p");
            d["reste"] = Math.Round(Math.Max(0, l.D("q") - l.D("p")), 3);
            lignes.Add(d);
        }
        var data = new DictO2();
        data["app"] = C.APP; data["lancement"] = lancement; data["token"] = S.Token();
        data["atelier"] = dest.Text; data["observation"] = obsv.Text; data["lignes"] = lignes;
        string p = Path.Combine(dir, "picking-" + lancement + ".json");
        File.WriteAllText(p, Json.DumpU(data));
        if (PortalServer.Current != null)
        {
            PortalServer.Current.SetPicking("matiere", data);   // SORTIE MATIERE sur mobile
            new PairDlg(App, PortalServer.Current.Url(),
                "Scannez le QR UNE SEULE FOIS avec le t\u00E9l\u00E9phone (m\u00EAme Wi-Fi que le PC).\n" +
                "Ensuite, chaque nouveau picking se t\u00E9l\u00E9charge automatiquement dans l'app mobile.\n" +
                "Serveur : " + PortalServer.Current.Ip() + ":" + PortalServer.Current.Port).Show();
        }
        else
        {
            new PairDlg(App, "PTS1|" + lancement + "|" + S.Token(),
                "Fichier : " + p + "\nTransf\u00E9rez \u00AB picking-" + lancement + ".json \u00BB sur le t\u00E9l\u00E9phone,\n" +
                "faites les sorties, puis revenez et cliquez \u00AB D\u00E9charger picking \u00BB.").Show();
        }
    }

    void Decharger()
    {
        var ofd = new OpenFileDialog();
        ofd.Title = "Fichier d\u00E9charg\u00E9 du portable";
        ofd.Filter = "JSON|*.json";
        if (ofd.ShowDialog(this) != DialogResult.OK) return;
        DictO data;
        try { data = (DictO)Json.Parse(File.ReadAllText(ofd.FileName)); }
        catch (Exception e) { U.Warn(this, "Fichier illisible : " + e.Message); return; }
        int ok = 0;
        if (data != null && data.ContainsKey("sorties") && data["sorties"] is List<object>)
            foreach (object o in (List<object>)data["sorties"])
            {
                DictO r = o as DictO;
                if (r == null) continue;
                try
                {
                    S.PickOut(Dg.S(r, "of").ToUpperInvariant(), Dg.S(r, "rf").ToUpperInvariant(),
                              Dg.S(r, "co").ToUpperInvariant(), Dg.S(r, "etiquette"), Dg.S(r, "emplacement"));
                    ok++;
                }
                catch (ValueError e) { U.Warn(this, e.Message); }
            }
        Refresh();
        U.Info(this, ok + " sortie(s) int\u00E9gr\u00E9e(s) depuis le portable.\nLe picking est mis \u00E0 jour automatiquement.");
    }

    void Imprimer()
    {
        var tr = new StringBuilder();
        foreach (object[] pair in Lignes())
        {
            Row l = (Row)pair[1];
            string n = Dg.S((DictO)pair[0], "n");
            var parEmp = new SortedDictionary<string, double>();
            foreach (DictO m in S.Moves(l.S("rf"), l.S("co"), n))
            {
                string k = Dg.S(m, "emp", "-");
                if (parEmp.ContainsKey(k)) parEmp[k] += U.Num(m["qt"]);
                else parEmp[k] = U.Num(m["qt"]);
            }
            string emp = string.Join(", ", parEmp.Select(kv => kv.Key + " : " + U.F3(kv.Value)));
            if (emp == "") emp = "-";
            List<Row> e0 = S.Q("SELECT * FROM eti WHERE rf=? AND co=? LIMIT 1", l.S("rf"), l.S("co"));
            string lz = e0.Count > 0 ? U.F3(S.Laize(e0[0])) : "-";
            tr.Append("<tr><td>" + U.Esc(lancement) + "</td><td>" + U.Esc(l.S("rf")) + "</td><td>" + U.Esc(l.S("co")) + "</td>"
                + "<td>" + U.F3(l.D("q")) + "</td><td>" + U.F3(l.D("p")) + "</td><td>" + U.Esc(emp) + "</td><td>" + lz + "</td></tr>");
        }
        U.OpenHtml("<h3>D\u00E9tail de sortie \u2013 Lancement " + U.Esc(lancement) + "</h3>" +
            "<table><tr><th>N\u00B0 Lancement</th><th>R\u00E9f\u00E9rence</th><th>Coloris</th><th>Besoin</th>" +
            "<th>Sortie</th><th>Qt\u00E9 par emplacement</th><th>Laize</th></tr>" + tr.ToString() + "</table>");
    }
}
}

// ===== part09c_flot.cs =====
// \u2500\u2500\u2500 Fen\u00EAtre 1 : Fabrication du L \u2500\u2500 liste des lancements, Cr\u00E9er / D\u00E9tails \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictO2 = System.Collections.Generic.Dictionary<string, object>;

public class FabL : Win
{
    TextBox q, ft;
    Label titre;
    Grid g, go;

    public FabL(App app) : base(app, "Fabrication du L", "1000x640")
    {
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Fill; top.Height = 40;
        top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Lab(null, "Recherche L :"));
        q = UI.Ent(14); top.Controls.Add(q);
        var labft = UI.Lab(null, "Filtre tiers :"); labft.Margin = new Padding(10, 3, 2, 2);
        top.Controls.Add(labft);
        ft = UI.Ent(14); top.Controls.Add(ft);
        top.Controls.Add(UI.Btn("Afficher \u25B6", delegate { Fill(); }, false, 12));
        var rt = new FlowLayoutPanel(); rt.FlowDirection = FlowDirection.TopDown; rt.AutoSize = true; rt.WrapContents = false;
        rt.Controls.Add(UI.Btn("Cr\u00E9er \u270E", delegate { new DescL(App, null).Show(); }, false, 10));
        rt.Controls.Add(UI.Btn("D\u00E9tails \uD83D\uDC41", delegate { Details(); }, false, 10));
        top.Controls.Add(rt);

        var lab1 = UI.Lab(null, "Liste des Lancements");
        g = new Grid(null, new[] { "N\u00B0 L", "Date", "\u00C9tat", "Tiers", "Coll." },
                     new[] { 150, 110, 110, 110, 80 }, 9, Pick, Details, null);
        titre = UI.Lab(null, "Liste des OFs attach\u00E9s au L");
        go = new Grid(null, new[] { "OFs", "Code mod\u00E8le", "Indice", "Date" },
                      new[] { 170, 180, 90, 110 }, 6, null, null, null);
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.Height = 40; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 10));

        g.Height = 9 * 20 + 26; go.Height = 6 * 20 + 26;
        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(titre, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(go, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);
        Fill();
    }

    public void Fill()
    {
        string qq = q.Text.Trim().ToUpperInvariant(), ftt = ft.Text.Trim().ToUpperInvariant();
        var L = new List<DictO>(); var vus = new HashSet<string>();
        foreach (DictO r in S.Lancements())
        {
            string lan = Dg.S(r, "lancement");
            if (vus.Contains(lan)) continue;
            if (qq != "" && !lan.StartsWith(qq)) continue;
            if (ftt != "" && !Dg.S(r, "tiers").ToUpperInvariant().Contains(ftt)) continue;
            vus.Add(lan);
            L.Add(r);
        }
        var rows = new List<GRow>();
        foreach (DictO r in L)
            rows.Add(new GRow(Dg.S(r, "lancement"),
                new[] { Dg.S(r, "lancement"), Dg.S(r, "date"), Dg.S(r, "st"), Dg.S(r, "tiers", "-"), Dg.S(r, "regroup", "-") },
                Dg.S(r, "etat") == "A sortir"));
        g.Fill(rows);
        Pick(g.Cur);
    }

    void Pick(string cur)
    {
        titre.Text = "Liste des OFs attach\u00E9s au L " + (cur ?? "");
        var rows = new List<GRow>();
        if (cur != null)
            foreach (DictO r in S.Lancements())
                if (Dg.S(r, "lancement") == cur)
                    rows.Add(new GRow(Dg.S(r, "n"),
                        new[] { Dg.S(r, "n"), Dg.S(r, "modele", "-"), Dg.S(r, "regroup", "1"), Dg.S(r, "date") }, false));
        go.Fill(rows);
    }

    void Details()
    {
        if (g.Cur == null) { U.Warn(this, "S\u00E9lectionnez un lancement."); return; }
        new DefL(App, g.Cur).Show();
    }
}

// \u2500\u2500\u2500 Fen\u00EAtre 2 : Description d'un L \u2500\u2500 rattache les OF disponibles (cr\u00E9e le N\u00B0 L auto) \u2500\u2500\u2500
public class DescL : Win
{
    string lan;
    HashSet<string> checkedSet;
    ComboBox vtype;
    TextBox vl, vd, fof;
    TextBox vt;
    Grid g1, g2;

    public DescL(App app, string lan) : base(app, "Description d'un L", "1000x680")
    {
        this.lan = lan;
        checkedSet = new HashSet<string>();
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Fill; top.Height = 34;
        top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Lab(null, "Type :"));
        vtype = new ComboBox(); vtype.DropDownStyle = ComboBoxStyle.DropDownList;
        vtype.Font = C.FONT; vtype.Width = 70;
        vtype.Items.Add("L"); vtype.Items.Add("LT"); vtype.Items.Add("LP");
        vtype.SelectedIndex = lan != null ? (lan.StartsWith("LT") ? 1 : (lan.StartsWith("LP") ? 2 : 0)) : 0;
        top.Controls.Add(vtype);
        var labn = UI.Lab(null, "Num\u00E9ro du L"); labn.Margin = new Padding(10, 3, 2, 2);
        top.Controls.Add(labn);
        vl = UI.Ent(16); vl.Text = lan ?? AutoL(); top.Controls.Add(vl);
        var labd = UI.Lab(null, "Date"); labd.Margin = new Padding(10, 3, 2, 2);
        top.Controls.Add(labd);
        vd = UI.Ent(12); vd.Text = U.TodayFr(); top.Controls.Add(vd);
        vt = new TextBox();
        new CodeField(top, App, "client", "Tiers", vt, 0, 10);

        var lab1 = UI.Lab(null, "OF Rattach\u00E9s");
        g1 = new Grid(null, new[] { "OF", "Mod\u00E8le", "Compteur", "Date", "Atelier" },
                      new[] { 170, 150, 90, 110, 160 }, 5, null, null, null);
        g1.Height = 5 * 20 + 26;
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.Height = 34; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Consulter \uD83D\uDC41", delegate { Consulter(); }, false, 12));
        bar.Controls.Add(UI.Btn("Rattacher \u2714 (cr\u00E9e le N\u00B0 L auto)", delegate { Rattacher(); }, false, 30));
        var labf = UI.Lab(null, "Filtre OF"); labf.Margin = new Padding(14, 3, 2, 2);
        bar.Controls.Add(labf);
        fof = UI.Ent(16); bar.Controls.Add(fof);
        bar.Controls.Add(UI.Btn("Filtrer \uD83D\uDD0D", delegate { Fill(); }, false, 10));
        var lab2 = UI.Lab(null, "OFs Disponibles");
        g2 = new Grid(null, new[] { "S\u00E9l.", "OF", "Envoi", "Mod\u00E8le", "Comp", "Date", "Atelier" },
                      new[] { 50, 180, 120, 140, 70, 110, 160 }, 10, null, Check, null);
        g2.Height = 10 * 20 + 26;
        var bar2 = new FlowLayoutPanel(); bar2.Dock = DockStyle.Fill; bar2.Height = 40; bar2.BackColor = Color.White; bar2.WrapContents = false;
        bar2.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 10));

        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar2, 0, r++);
        vtype.SelectedIndexChanged += delegate { vl.Text = AutoL(); };
        Fill();
    }

    string AutoL()
    {
        string p = vtype.Text == "" ? "L" : vtype.Text;
        string key = p == "LT" ? "num_lt" : (p == "LP" ? "num_lp" : "num_l");
        long start = p == "LT" ? 1000 : (p == "LP" ? 2000 : 44726);
        long v;
        if (!long.TryParse(S.Cfg(key, start.ToString()), out v)) v = start;
        return p + (v + 1) + " (auto)";
    }

    void Fill()
    {
        var rat = new List<DictO>();
        if (lan != null)
            foreach (DictO r in S.Lancements())
                if (Dg.S(r, "lancement") == lan) rat.Add(r);
        var r1 = new List<GRow>();
        foreach (DictO r in rat)
            r1.Add(new GRow(Dg.S(r, "n"),
                new[] { Dg.S(r, "n"), Dg.S(r, "modele", "-"), Dg.S(r, "pcs"), Dg.S(r, "date"), Dg.S(r, "dest", "-") }, false));
        g1.Fill(r1);
        string f = fof.Text.Trim().ToUpperInvariant();
        var r2 = new List<GRow>();
        foreach (Row c in S.OfsDisponibles())
        {
            if (f != "" && !c.S("n").StartsWith(f)) continue;
            var d = S.OfdGet(c.S("n"));
            r2.Add(new GRow(c.S("n"),
                new[] { checkedSet.Contains(c.S("n")) ? "\u2611" : "\u2610", c.S("n"), "-", Dg.S(d, "modele", "-"),
                        c.S("pcs"), c.S("d"), Dg.S(d, "atelier", "-") }, false));
        }
        g2.Fill(r2);
    }

    void Check()
    {
        if (g2.Cur == null) return;
        if (!checkedSet.Add(g2.Cur)) checkedSet.Remove(g2.Cur);
        Fill();
    }

    void Rattacher()
    {
        if (checkedSet.Count == 0) { U.Warn(this, "Cochez (double-clic) au moins un OF disponible."); return; }
        List<string> ofs = checkedSet.OrderBy(x => x).ToList();
        string tiers = vt.Text.Trim().ToUpperInvariant();
        if (lan != null)
        {
            S.AttachOf(lan, ofs, tiers);
            U.Info(this, "OF rattach\u00E9(s) au lancement " + lan + ".");
            checkedSet.Clear();
            Fill();
        }
        else
        {
            string l = S.NewLancement(ofs, tiers, vtype.Text == "" ? "L" : vtype.Text);
            lan = l; vl.Text = l;
            int n = ofs.Count;
            checkedSet.Clear();
            Fill();
            U.Info(this, "N\u00B0 de lancement " + lan + " cr\u00E9\u00E9 automatiquement\npour " + n + " OF(s) s\u00E9lectionn\u00E9(s).");
        }
    }

    void Consulter()
    {
        if (lan == null) { U.Warn(this, "Cr\u00E9ez d'abord le lancement."); return; }
        new DefL(App, lan).Show();
    }
}

// \u2500\u2500\u2500 Fen\u00EAtre 3 : D\u00E9finition du lancement (mati\u00E8res + tailles) \u2500\u2500\u2500
public class DefL : Win
{
    public DefL(App app, string lan) : base(app, "D\u00E9finition", "1000x640")
    {
        List<DictO> ofs = new List<DictO>();
        foreach (DictO oo in S.Lancements())
            if (Dg.S(oo, "lancement") == lan) ofs.Add(oo);

        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new FlowLayoutPanel(); top.Dock = DockStyle.Fill; top.Height = 34; top.BackColor = Color.White; top.WrapContents = false;
        top.Controls.Add(UI.Lab(null, "Num\u00E9ro Lancement :"));
        var llan = new Label(); llan.Text = lan;
        llan.BackColor = Color.FromArgb(0xea, 0xf1, 0xfb); llan.BorderStyle = BorderStyle.FixedSingle;
        llan.Width = 12 * 7 + 10; llan.Font = C.FONTB;
        top.Controls.Add(llan);
        var labc = UI.Lab(null, "Client :"); labc.Margin = new Padding(10, 3, 2, 2); top.Controls.Add(labc);
        var vc = UI.Ent(12); vc.Text = ofs.Count > 0 ? Dg.S(ofs[0], "tiers") : ""; top.Controls.Add(vc);
        var labcm = UI.Lab(null, "Co\u00FBt Minute MO :"); labcm.Margin = new Padding(10, 3, 2, 2); top.Controls.Add(labcm);
        var vcm = UI.Ent(8);
        vcm.Text = ofs.Count > 0 ? Dg.S(S.OfdGet(Dg.S(ofs[0], "n")), "cout_minute", "0,00") : "0,00";
        top.Controls.Add(vcm);

        var lab1 = UI.Lab(null, "Mati\u00E8re");
        var gm = new Grid(null, new[] { "Mati\u00E8re", "RfMCF", "Ebm", "ET", "LgRx", "TM", "Vcm", "PxMati", "MPl" },
                          new[] { 170, 80, 60, 60, 90, 50, 60, 90, 60 }, 6, null, null, new[] { 4, 6, 7, 8 });
        gm.Height = 6 * 20 + 26;
        var lab2 = UI.Lab(null, "Mod\u00E8le(s) :");
        var mod = UI.Text(40, 2);

        List<Sz> sizes = S.Sizes();
        var cols = new List<string> { "Laize", "Coloris", "Libcol" };
        foreach (Sz s in sizes) cols.Add(s.T);
        cols.Add("Total");
        var ws = new List<int> { 70, 80, 110 };
        foreach (Sz s in sizes) ws.Add(50);
        ws.Add(70);
        var right = new List<int>();
        for (int i = 3; i < cols.Count; i++) right.Add(i);
        var gt = new Grid(null, cols.ToArray(), ws.ToArray(), 8, null, null, right.ToArray());
        gt.Height = 8 * 20 + 26;
        var tot = new Label(); tot.Text = "Total : 0"; tot.Width = 120;
        tot.TextAlign = ContentAlignment.MiddleRight; tot.Font = C.FONTB;
        tot.BorderStyle = BorderStyle.FixedSingle; tot.BackColor = Color.White;

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.Height = 40; bar.BackColor = Color.White; bar.WrapContents = false;
        var qbtn = UI.Btn("Quitter \u2715", delegate { Close(); }, true, 10);
        bar.Controls.Add(qbtn);

        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(gm, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(mod, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(gt, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(tot, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);

        var mrows = new List<GRow>();
        var mods = new SortedSet<string>();
        var qOf = new Dictionary<string, DictO>();
        foreach (DictO rr in ofs)
        {
            string n = Dg.S(rr, "n");
            mods.Add(Dg.S(rr, "modele", "-"));
            DictO q = null;
            string tls = S.Q("SELECT tl FROM cmd WHERE n=?", n).Count > 0
                ? S.Q("SELECT tl FROM cmd WHERE n=?", n)[0].S("tl") : null;
            try { q = Json.Parse(tls) as DictO; } catch { q = null; }
            if (q == null) q = new DictO2();
            qOf[n] = q;
        }
        foreach (DictO rr in ofs)
        {
            string n = Dg.S(rr, "n");
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", n))
            {
                List<Row> nn = S.Q("SELECT c FROM nom WHERE rf=? AND co=?", l.S("rf"), l.S("co"));
                mrows.Add(new GRow(n + "|" + l.S("rf") + "|" + l.S("co"),
                    new[] { l.S("rf"), l.S("co"), "-", "ML", U.F3(l.D("q")), "C", "4,0",
                            U.F3(nn.Count > 0 ? nn[0].D("c") : 0), "20" }, false));
            }
        }
        gm.Fill(mrows);
        mod.Text = string.Join(", ", mods.ToArray());
        var trows = new List<GRow>();
        double totv = 0;
        foreach (DictO rr in ofs)
        {
            string n = Dg.S(rr, "n");
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", n))
            {
                var q = qOf.ContainsKey(n) ? qOf[n] : new DictO2();
                var vals = new List<string> { "1,430", l.S("co"), S.Lib("coloris", l.S("co")) ?? l.S("co") };
                double ssum = 0;
                foreach (Sz sz in sizes)
                {
                    double v = Math.Round(Dg.Taille(q, sz.T) * sz.C, 3);
                    ssum += v;
                    vals.Add(U.F3(v));
                }
                vals.Add(U.F3(ssum));
                totv += ssum;
                trows.Add(new GRow(n + "|" + l.S("rf") + "|" + l.S("co") + "|t", vals.ToArray(), false));
            }
        }
        gt.Fill(trows);
        tot.Text = "Total : " + U.F3(totv);
    }
}

// \u2500\u2500\u2500 Fen\u00EAtre 4 : Transfert Sortie Mati\u00E8re \u2500\u2500 le lancement passe dans \u00AB Sortie mati\u00E8re OF \u00BB \u2500\u2500\u2500
public class Transfert : Win
{
    Grid g;

    public Transfert(App app) : base(app, "Transfert Sortie Mati\u00E8re", "900x480")
    {
        g = new Grid(null, new[] { "Num\u00E9ro Lancem.", "Tiers", "Observation" },
                     new[] { 180, 140, 420 }, 12, null, null, null);
        g.Dock = DockStyle.Fill;
        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Bottom; bar.Height = 40; bar.BackColor = Color.White; bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("Transf\u00E9rer \u27A1", delegate { Transferer(); }, false, 14));
        bar.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 10));
        Body.Controls.Add(g); Body.Controls.Add(bar);
        Fill();
    }

    void Fill()
    {
        var vus = new HashSet<string>();
        var rows = new List<GRow>();
        foreach (DictO r in S.Lancements())
        {
            string lan = Dg.S(r, "lancement");
            if (vus.Contains(lan)) continue;
            vus.Add(lan);
            bool tr = false;
            foreach (DictO x in S.Lancements())
                if (Dg.S(x, "lancement") == lan)
                {
                    var d = S.OfdGet(Dg.S(x, "n"));
                    object o;
                    if (d.TryGetValue("transfere", out o) && !Equals(o, 0)) tr = true;
                }
            string obsp = Dg.S(r, "obs");
            if (obsp.Length > 40) obsp = obsp.Substring(0, 40);
            rows.Add(new GRow(lan, new[] { lan, Dg.S(r, "tiers", "-"), (tr ? "TRANSF\u00C9R\u00C9 \u2714 " : "") + obsp }, false));
        }
        g.Fill(rows);
    }

    void Transferer()
    {
        if (g.Cur == null) { U.Warn(this, "S\u00E9lectionnez un lancement \u00E0 transf\u00E9rer."); return; }
        string cur = g.Cur;
        foreach (DictO r in S.Lancements())
            if (Dg.S(r, "lancement") == cur)
            {
                var d = S.OfdGet(Dg.S(r, "n"));
                d["transfere"] = (long)1;
                S.OfdSet(Dg.S(r, "n"), d);
            }
        S.Log("Lancement " + cur + " transf\u00E9r\u00E9 vers Sortie mati\u00E8re OF");
        Fill();
        U.Info(this, "Lancement " + cur + " transf\u00E9r\u00E9.\nIl appara\u00EEt dans \u00AB Sortie mati\u00E8re OF \u00BB pour le picking.");
    }
}
}

// ===== part09d_flot.cs =====
// \u2500\u2500\u2500 Fen\u00EAtre n\u00B001 : Cr\u00E9ation d'un N\u00B0 d'envoi group\u00E9 \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictO2 = System.Collections.Generic.Dictionary<string, object>;

public class EnvoiGroupeDlg : Win
{
    Action<string, string> cb;
    TextBox vt;

    public EnvoiGroupeDlg(App app, Action<string, string> cb) : base(app, "Cr\u00E9ation d'un N\u00B0 d'envoi group\u00E9", "560x200")
    {
        this.cb = cb;
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 4;
        Body.Controls.Add(tlp);
        vt = new TextBox();
        new CodeField(tlp, App, "client", "Tiers", vt, 0, 12);
        var fr = new FlowLayoutPanel(); fr.BackColor = Color.White; fr.AutoSize = true; fr.WrapContents = false;
        fr.Controls.Add(UI.Btn("Enregistrer \uD83D\uDCBE", delegate { Ok(); }, false, 14));
        fr.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));
        tlp.Controls.Add(fr, 0, 1);
        tlp.SetColumnSpan(fr, 4);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize));
    }

    void Ok()
    {
        string tiers = vt.Text.Trim().ToUpperInvariant();
        if (tiers == "") { U.Warn(this, "Renseignez le tiers."); return; }
        long n = S.NextNum("num_env", 1264400049);
        string env = n.ToString();
        S.SetCfg("last_env", env);
        S.SetCfg("envtiers:" + env, tiers);
        S.Log("N\u00B0 d'envoi group\u00E9 " + env + " cr\u00E9\u00E9 (tiers " + tiers + ")");
        Close();
        if (cb != null) cb(env, tiers);
    }
}

// \u2500\u2500\u2500 Fen\u00EAtre n\u00B002 : REGROUPEMENT FOURNITURES \u2500\u2500\u2500
public class RegroupFourn : Win
{
    HashSet<string> checkedSet;
    TextBox vr, vt, vd;
    Grid g1, gs, g2;

    public RegroupFourn(App app) : base(app, "Regroupement OFs Fourniture", "1250x720")
    {
        checkedSet = new HashSet<string>();
        var tlp = new TableLayoutPanel();
        tlp.Dock = DockStyle.Fill; tlp.BackColor = Color.White; tlp.ColumnCount = 1;
        Body.Controls.Add(tlp);

        var top = new GroupBox(); top.Text = "Regroupement Fournitures"; top.Font = C.FONT;
        top.AutoSize = true;
        var toptlp = new TableLayoutPanel(); toptlp.AutoSize = true; toptlp.ColumnCount = 7;
        toptlp.Controls.Add(UI.Lab(null, "N\u00B0 Regroupement"), 0, 0);
        vr = UI.Ent(14); toptlp.Controls.Add(vr, 1, 0);
        vt = new TextBox();
        var vtTlp = new TableLayoutPanel();
        toptlp.Controls.Add(vtTlp, 2, 0);
        new CodeField(vtTlp, App, "client", "Tiers", vt, 0, 8);
        toptlp.Controls.Add(UI.Lab(null, "Date"), 4, 0);
        vd = UI.Ent(12); vd.Text = U.TodayFr(); toptlp.Controls.Add(vd, 5, 0);
        toptlp.Controls.Add(UI.Btn("Nouveau \uD83D\uDD15", delegate { Nouveau(); }, false, 12), 6, 0);
        top.Controls.Add(toptlp);

        var lab1 = UI.Lab(null, "Envois rattach\u00E9s au N\u00B0 de regroupement");
        g1 = new Grid(null, new[] { "Coll.", "N\u00B0 Envoi", "Mod\u00E8le", "Compteur", "Code Atelier", "Atelier", "Code Fourn." },
                      new[] { 50, 150, 130, 90, 110, 120, 130 }, 5, null, null, null);
        g1.Height = 5 * 20 + 26;

        var bar = new FlowLayoutPanel(); bar.Dock = DockStyle.Fill; bar.Height = 40; bar.BackColor = Color.White;
        bar.WrapContents = false;
        bar.Controls.Add(UI.Btn("D\u00E9tacher \u2B07", delegate { Detacher(); }, true, 12));
        var att = UI.Btn("Attacher \u2B06", delegate { Attacher(); }, false, 12); att.Margin = new Padding(6, 3, 3, 3);
        bar.Controls.Add(att);
        var impr = UI.Btn("Imprimer Simulation \uD83D\uDDA8", delegate { Impr(); }, false, 18);
        impr.Margin = new Padding(6, 3, 3, 3);
        bar.Controls.Add(impr);

        var sim = new GroupBox(); sim.Text = "Simulation Regroupement"; sim.Font = C.FONT; sim.AutoSize = true;
        gs = new Grid(null, new[] { "Code Ref.", "Code Col.", "Type", "Besoin", "Manque" },
                      new[] { 160, 100, 60, 100, 100 }, 6, null, null, new[] { 3, 4 });
        gs.Height = 6 * 20 + 26;
        sim.Controls.Add(gs);

        var lab2 = UI.Lab(null, "OFs disponibles");
        g2 = new Grid(null, new[] { "S\u00E9l.", "N\u00B0 OF", "N\u00B0 Envoi", "Mod\u00E8le", "Compteur", "Date", "Code Atelier", "Atelier",
                                    "Code Fourn.", "Fournisseur" },
                      new[] { 40, 150, 130, 120, 80, 100, 100, 110, 110, 130 }, 8, null, Check, null);
        g2.Height = 8 * 20 + 26;
        var bar2 = new FlowLayoutPanel(); bar2.Dock = DockStyle.Fill; bar2.Height = 40;
        bar2.BackColor = Color.White; bar2.WrapContents = false;
        var quit = UI.Btn("Quitter \u2715", delegate { Close(); }, true, 10);
        quit.Margin = new Padding(6, 3, 3, 3);
        bar2.Controls.Add(quit);

        int r = 0;
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(top, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g1, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(sim, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(lab2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(g2, 0, r++);
        tlp.RowStyles.Add(new RowStyle(SizeType.AutoSize)); tlp.Controls.Add(bar2, 0, r++);
        Fill();
    }

    void Nouveau()
    {
        new EnvoiGroupeDlg(App, delegate (string env, string tiers)
        {
            vr.Text = env; vt.Text = tiers;
            Fill();
        }).Show();
    }

    List<object[]> Envois()
    {
        var out1 = new List<object[]>();
        string rg = vr.Text.Trim();
        foreach (Row c in S.Cmds())
        {
            var d = S.OfdGet(c.S("n"));
            if (Dg.S(d, "regroup") == rg) out1.Add(new object[] { c, d });
        }
        return out1;
    }

    void Fill()
    {
        string rg = vr.Text.Trim();
        var r1 = new List<GRow>();
        foreach (object[] e in Envois())
        {
            Row c = (Row)e[0]; DictO d = (DictO)e[1];
            r1.Add(new GRow(c.S("n"),
                new[] { Dg.S(d, "regroup", ""), rg == "" ? "-" : rg, Dg.S(d, "modele", "-"), c.S("pcs"),
                        Dg.S(d, "code_atelier", ""), Dg.S(d, "atelier", ""), Dg.S(d, "fournisseur", "") }, false));
        }
        g1.Fill(r1);
        // simulation : besoin vs stock logique par r\u00E9f\u00E9rence/coloris des OFs du regroupement
        var besoin = new Dictionary<string, double>();
        var ordre = new List<string>();
        foreach (object[] e in Envois())
        {
            Row c = (Row)e[0];
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", c.S("n")))
            {
                string k = l.S("rf") + "|" + l.S("co");
                if (besoin.ContainsKey(k)) besoin[k] += l.D("q");
                else { besoin[k] = l.D("q"); ordre.Add(k); }
            }
        }
        ordre.Sort();
        var rs = new List<GRow>();
        foreach (string k in ordre)
        {
            string[] pc = k.Split('|');
            double dispo = S.Logique(pc[0], pc[1]) - S.Reserved(pc[0], pc[1]);
            double manque = Math.Max(0, besoin[k] - dispo);
            rs.Add(new GRow(k, new[] { pc[0], pc[1], "F", U.F3(besoin[k]), U.F3(manque) }, manque > .0005));
        }
        gs.Fill(rs);
        var r2 = new List<GRow>();
        foreach (Row c in S.OfsDisponibles())
        {
            var d = S.OfdGet(c.S("n"));
            r2.Add(new GRow(c.S("n"),
                new[] { checkedSet.Contains(c.S("n")) ? "\u2611" : "\u2610", c.S("n"), Dg.S(d, "envoi", "-"),
                        Dg.S(d, "modele", "-"), c.S("pcs"), c.S("d"), Dg.S(d, "code_atelier", ""),
                        Dg.S(d, "atelier", ""), Dg.S(d, "fournisseur", ""), "-" }, false));
        }
        g2.Fill(r2);
    }

    void Check()
    {
        if (g2.Cur == null) return;
        if (!checkedSet.Add(g2.Cur)) checkedSet.Remove(g2.Cur);
        Fill();
    }

    void Attacher()
    {
        if (vr.Text.Trim() == "") { U.Warn(this, "Cr\u00E9ez ou saisissez d'abord un N\u00B0 de regroupement."); return; }
        if (checkedSet.Count == 0) { U.Warn(this, "Cochez au moins un OF disponible."); return; }
        List<string> ofs = checkedSet.OrderBy(x => x).ToList();
        string rg = vr.Text.Trim();
        string tiers = vt.Text.Trim().ToUpperInvariant();
        foreach (string n in ofs)
        {
            var d = S.OfdGet(n);
            d["regroup"] = rg;
            d["tiers"] = tiers;
            S.OfdSet(n, d);
        }
        S.Log("OF " + string.Join(", ", ofs.ToArray()) + " rattach\u00E9(s) au regroupement " + vr.Text);
        checkedSet.Clear();
        Fill();
    }

    void Detacher()
    {
        if (g1.Cur == null) { U.Warn(this, "S\u00E9lectionnez un envoi rattach\u00E9."); return; }
        var d = S.OfdGet(g1.Cur);
        d["regroup"] = "";
        S.OfdSet(g1.Cur, d);
        Fill();
    }

    void Impr()
    {
        var tr = new StringBuilder();
        foreach (string[] v in gs.AllVals())
        {
            tr.Append("<tr>");
            foreach (string v2 in v) tr.Append("<td>" + U.Esc(v2) + "</td>");
            tr.Append("</tr>");
        }
        U.OpenHtml("<h3>Simulation Regroupement " + U.Esc(vr.Text) + "</h3>" +
                   "<table><tr><th>Code Ref.</th><th>Code Col.</th><th>Type</th><th>Besoin</th><th>Manque</th></tr>" +
                   tr.ToString() + "</table>");
    }
}
}

// ===== part09e_flot.cs =====
// \u2500\u2500\u2500 Fen\u00EAtre n\u00B03 : Sortie Picking Fournitures \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;

using DictO = System.Collections.Generic.IDictionary<string, object>;
using DictO2 = System.Collections.Generic.Dictionary<string, object>;

public class SortiePickFourn : Win
{
    Dictionary<string, TextBox> V;
    Grid[] g;
    string[] tabs = { "BESOIN", "QUANTIT\u00C9S A SORTIR", "SORTIE" };

    public SortiePickFourn(App app) : base(app, "Sortie Picking Fournitures", "1250x640")
    {
        V = new Dictionary<string, TextBox>();
        foreach (string k in new[] { "cl", "of", "env", "et", "at" }) V[k] = UI.Ent(k == "at" ? 30 : 12);
        V["env"].Text = S.Cfg("last_env");

        var top = new GroupBox(); top.Font = C.FONT; top.AutoSize = true;
        var toptlp = new TableLayoutPanel(); toptlp.AutoSize = true;
        toptlp.Controls.Add(UI.Lab(null, "Client :"), 0, 0); toptlp.Controls.Add(V["cl"], 1, 0);
        toptlp.Controls.Add(UI.Lab(null, "N\u00B0OF :"), 0, 1); toptlp.Controls.Add(V["of"], 1, 1);
        toptlp.Controls.Add(UI.Lab(null, "N\u00B0 Envoi :"), 0, 2); toptlp.Controls.Add(V["env"], 1, 2);
        toptlp.Controls.Add(UI.Lab(null, "Etat :"), 0, 3); toptlp.Controls.Add(V["et"], 1, 3);
        toptlp.Controls.Add(UI.Lab(null, "Atelier de montage :"), 0, 4); toptlp.Controls.Add(V["at"], 1, 4);
        top.Controls.Add(toptlp);

        var rt = new FlowLayoutPanel(); rt.FlowDirection = FlowDirection.TopDown; rt.AutoSize = true; rt.WrapContents = false;
        rt.Controls.Add(UI.Btn("Cr\u00E9er le picking \uD83D\uDDA8", delegate { Creer(); }, false, 20));
        rt.Controls.Add(UI.Btn("Charger Portable \uD83D\uDCF1", delegate { Charger(); }, false, 20));
        rt.Controls.Add(UI.Btn("Picking Fournitures \uD83D\uDCE6", delegate { Pickf(); }, false, 20));
        rt.Controls.Add(UI.Btn("Quitter \u2715", delegate { Close(); }, true, 12));

        var lg = new GroupBox(); lg.Text = ""; lg.Font = C.FONT; lg.AutoSize = true;
        var lgf = new FlowLayoutPanel(); lgf.FlowDirection = FlowDirection.TopDown; lgf.AutoSize = true; lgf.WrapContents = false;
        foreach (var e in new[] {
                     new object[] { Color.FromArgb(0xff, 0x00, 0x00), "Besoin Non Satisfait" },
                     new object[] { Color.FromArgb(0x4c, 0xb8, 0x66), "Qt\u00E9 S\u00E9lectionn\u00E9e" },
                     new object[] { Color.FromArgb(0xff, 0xff, 0x00), "Existence d'un Stock Sp\u00E9cial" },
                     new object[] { Color.FromArgb(0xc9, 0xc9, 0xea), "Qt\u00E9 Sortie" },
                     new object[] { Color.FromArgb(0x00, 0x00, 0xff), "Ligne trait\u00E9e enti\u00E8rement" } })
            lgf.Controls.Add(Swatch((Color)e[0], (string)e[1]));
        lg.Controls.Add(lgf);

        var topf = new FlowLayoutPanel(); topf.Dock = DockStyle.Top; topf.Height = 150;
        topf.BackColor = Color.White; topf.WrapContents = false;
        topf.Controls.Add(top); topf.Controls.Add(rt); topf.Controls.Add(lg);
        Body.Controls.Add(topf);

        var nb = new TabControl(); nb.Dock = DockStyle.Fill;
        g = new Grid[tabs.Length];
        var cols = new[] { "R\u00E9f\u00E9rence", "Coloris", "Libell\u00E9", "Aff", "Besoin", "Qt\u00E9 LOGIQUE \u00E0 Sortir", "Qt\u00E9 COLLECTION \u00E0 Sortir",
                           "Qt\u00E9 SECONDAIRE \u00E0 Sortir", "Qt\u00E9 SP\u00C9CIALE \u00E0 Sortir", "Qt\u00E9 Sortie", "Trait\u00E9" };
        var w = new[] { 140, 80, 160, 60, 90, 110, 110, 110, 110, 90, 70 };
        for (int i = 0; i < tabs.Length; i++)
        {
            var page = new TabPage(tabs[i]);
            g[i] = new Grid(page, cols, w, 10, null, null, new[] { 4, 5, 6, 7, 8, 9 });
            g[i].Dock = DockStyle.Fill;
            nb.TabPages.Add(page);
        }
        Body.Controls.Add(nb);
        nb.BringToFront();
        RefreshRows();
    }

    static Control Swatch(Color c, string t)
    {
        var f = new FlowLayoutPanel(); f.AutoSize = true; f.WrapContents = false; f.Margin = new Padding(1);
        var s = new Panel(); s.BackColor = c; s.Width = 22; s.Height = 14;
        s.Margin = new Padding(1); s.BorderStyle = BorderStyle.FixedSingle;
        var l = UI.Lab(null, t); l.Margin = new Padding(4, 2, 2, 2);
        f.Controls.Add(s); f.Controls.Add(l);
        return f;
    }

    List<GRow> Lignes()
    {
        string ofStr = V["of"].Text.Trim().ToUpperInvariant();
        var rows = new List<GRow>();
        foreach (Row c in S.Cmds())
        {
            if (ofStr != "" && !c.S("n").StartsWith(ofStr)) continue;
            foreach (Row l in S.Q("SELECT * FROM cmdl WHERE n=?", c.S("n")))
            {
                double log = S.Logique(l.S("rf"), l.S("co"));
                double aSortir = Math.Max(0, l.D("q") - l.D("p"));
                rows.Add(new GRow(c.S("n") + "|" + l.S("rf") + "|" + l.S("co"),
                    new[] { l.S("rf"), l.S("co"), S.Lib("reference", l.S("rf")) ?? l.S("rf"), "-", U.F3(l.D("q")),
                            U.F3(Math.Min(aSortir, log)), "0,000", "0,000", "0,000", U.F3(l.D("p")),
                            l.D("p") >= l.D("q") - .0005 ? "\u2714" : "" },
                    log < aSortir));
            }
        }
        return rows;
    }

    void RefreshRows()
    {
        var rows = Lignes();
        for (int i = 0; i < g.Length; i++) g[i].Fill(rows);
    }

    void Creer()
    {
        RefreshRows();
        U.Info(this, "Picking cr\u00E9\u00E9 pour les OF saisis.");
    }

    void Charger()
    {
        string dir = Path.Combine(U.BaseDir(), "exports", "portable");
        Directory.CreateDirectory(dir);
        var lignes = new List<DictO>();
        foreach (GRow r in Lignes())
        {
            var d = new DictO2();
            d["of"] = r.Id.Split('|')[0];
            d["rf"] = r.V[0]; d["co"] = r.V[1];
            d["besoin"] = r.V[4];
            lignes.Add(d);
        }
        var data = new DictO2();
        data["app"] = C.APP; data["type"] = "fournitures"; data["token"] = S.Token();
        data["lignes"] = lignes;
        string p = Path.Combine(dir, "picking-fournitures.json");
        File.WriteAllText(p, Json.DumpU(data));
        if (PortalServer.Current != null)
        {
            PortalServer.Current.SetPicking("fourn", data);   // PICKING FOUR./DENT. sur mobile
            new PairDlg(App, PortalServer.Current.Url(),
                "Scannez le QR UNE SEULE FOIS avec le t\u00E9l\u00E9phone (m\u00EAme Wi-Fi que le PC).\n" +
                "Le picking fournitures s'affiche automatiquement dans l'app mobile.\n" +
                "Serveur : " + PortalServer.Current.Ip() + ":" + PortalServer.Current.Port).Show();
        }
        else
        {
            new PairDlg(App, "PTS1|FOURNITURES|" + S.Token(), "Fichier : " + p).Show();
        }
    }

    void Pickf()
    {
        RefreshRows();
        U.Info(this, Lignes().Count + " ligne(s) de picking affich\u00E9es.");
    }
}
}

// ===== part10_app.cs =====
// \u2500\u2500\u2500 \u00C9cran de d\u00E9marrage + Application principale + point d'entr\u00E9e \u2500\u2500\u2500
namespace PTS
{
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Threading;
using System.Windows.Forms;

public class StartScreen : Form
{
    Store S;
    ApplicationContext ctx;

    public StartScreen(Store s, ApplicationContext ctx)
    {
        S = s; this.ctx = ctx;
        Text = C.APP + " \u2013 Textile Management System";
        ClientSize = new Size(900, 620);
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(0xe8, 0xe8, 0xe8);

        var card = new Panel();
        card.Dock = DockStyle.Fill; card.BackColor = Color.White;
        card.BorderStyle = BorderStyle.Fixed3D;
        Controls.Add(card);

        Image logo = null;
        try { logo = UI.LogoImage(); } catch { logo = null; }
        Control head;
        if (logo != null)
        {
            var pb = new PictureBox();
            pb.Image = logo; pb.SizeMode = PictureBoxSizeMode.CenterImage;
            pb.Dock = DockStyle.None; pb.Width = Math.Min(logo.Width, 600);
            pb.Height = Math.Min(logo.Height, 260);
            pb.Location = new Point((900 - pb.Width) / 2, 40);
            head = pb;
        }
        else
        {
            var l = new Label(); l.Text = C.APP.ToUpper();
            l.ForeColor = Color.FromArgb(0x1b, 0x2a, 0x7a); l.BackColor = Color.White;
            l.Font = new Font("Segoe UI", 26, FontStyle.Bold);
            l.AutoSize = true; l.TextAlign = ContentAlignment.MiddleCenter;
            head = l;
        }
        card.Controls.Add(head);
        var t1 = new Label(); t1.Text = "PRO TEXTILE SYSTEME";
        t1.ForeColor = Color.FromArgb(0x1b, 0x2a, 0x7a); t1.BackColor = Color.White;
        t1.Font = new Font("Segoe UI", 30, FontStyle.Bold); t1.AutoSize = true;
        t1.Location = new Point(0, 320); t1.TextAlign = ContentAlignment.MiddleCenter;
        card.Controls.Add(t1);
        var t2 = new Label(); t2.Text = "TEXTILE MANAGEMENT SYSTEM";
        t2.ForeColor = Color.FromArgb(0xe8, 0xa0, 0x20); t2.BackColor = Color.White;
        t2.Font = new Font("Segoe UI", 15, FontStyle.Bold); t2.AutoSize = true;
        t2.Location = new Point(0, 380); t2.TextAlign = ContentAlignment.MiddleCenter;
        card.Controls.Add(t2);
        card.Resize += delegate
        {
            foreach (Control c in card.Controls)
                c.Location = new Point(Math.Max(0, (card.Width - c.Width) / 2), c.Location.Y);
        };

        var bar = new FlowLayoutPanel();
        bar.Dock = DockStyle.Bottom; bar.Height = 60; bar.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        bar.WrapContents = false;
        foreach (var e in new[] {
                     new object[] { "\uD83D\uDD11 Acc\u00E8s", (Action<App>)null },
                     new object[] { "\uD83D\uDCE5 R\u00E9ception", (Action<App>)(a => new NewRec(a).Show()) },
                     new object[] { "\u2696 Labo", (Action<App>)(a => new RetourLabo(a).Show()) },
                     new object[] { "\uD83D\uDCCA Stock", (Action<App>)(a => new Consult(a).Show()) },
                     new object[] { "\uD83D\uDCE6 Picking", (Action<App>)(a => new Picking(a).Show()) },
                     new object[] { "\u270E \u00C9dition", (Action<App>)(a => new Tiers(a).Show()) },
                     new object[] { "\uD83D\uDEA2 Marine", (Action<App>)(a => new SortieOF(a).Show()) },
                     new object[] { "\uD83D\uDCC8 Stat", (Action<App>)(a => new Histo(a).Show()) } })
        {
            Action<App> op = (Action<App>)e[1];
            var b = new Button();
            b.Text = (string)e[0]; b.Font = C.FONTB;
            b.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0); b.FlatStyle = FlatStyle.Popup;
            b.Width = 110; b.Height = 44; b.Margin = new Padding(3, 8, 3, 8);
            b.Click += delegate { Go(op); };
            bar.Controls.Add(b);
        }
        Controls.Add(bar);
    }

    void Go(Action<App> op)
    {
        var a = new App(S);
        ctx.MainForm = a;
        Hide();
        a.Show();
        if (op != null) a.ActivateDelayed(delegate { op(a); });
        Close();
    }
}

public class App : Form
{
    public Store S;
    Grid g;              // grille de la fen\u00EAtre \u00AB Liste r\u00E9ceptions \u00BB
    Label kp;
    Form listWin;

    public App(Store s)
    {
        S = s;
        Text = C.APP + " \u2013 Textile Management System";
        ClientSize = new Size(1100, 700);
        BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        StartPosition = FormStartPosition.CenterScreen;

        var body = new Panel();
        body.Dock = DockStyle.Fill; body.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        Control head;
        Image homeLogo = null;
        try { homeLogo = UI.LogoImage(); } catch { homeLogo = null; }
        if (homeLogo != null)
        {
            var pb = new PictureBox();
            pb.Image = homeLogo; pb.SizeMode = PictureBoxSizeMode.CenterImage;
            pb.Anchor = AnchorStyles.None;
            pb.Width = Math.Min(homeLogo.Width, 500); pb.Height = Math.Min(homeLogo.Height, 300);
            body.Controls.Add(pb);
            body.Resize += delegate { try { pb.Location = new Point((body.ClientSize.Width - pb.Width) / 2, (body.ClientSize.Height - pb.Height) / 2); } catch { } };
            head = pb;
        }
        else
        {
            var l = new Label(); l.Text = C.APP.ToUpper();
            l.ForeColor = Color.FromArgb(0x1b, 0x2a, 0x7a); l.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
            l.Font = new Font("Segoe UI", 30, FontStyle.Bold); l.AutoSize = true;
            l.Anchor = AnchorStyles.None;
            body.Controls.Add(l);
            body.Resize += delegate { try { l.Location = new Point((body.ClientSize.Width - l.Width) / 2, (body.ClientSize.Height - l.Height) / 2); } catch { } };
            head = l;
        }

        var hd = new Panel();
        hd.Dock = DockStyle.Top; hd.Height = 70; hd.BackColor = Color.FromArgb(0x1b, 0x2a, 0x7a);
        Image logo = null;
        try { logo = UI.LogoImage(); } catch { logo = null; }
        if (logo != null)
        {
            var pb = new PictureBox();
            pb.Image = logo; pb.SizeMode = PictureBoxSizeMode.CenterImage;
            pb.Dock = DockStyle.Left; pb.Width = logo.Width; pb.Height = hd.Height;
            hd.Controls.Add(pb);
        }
        else
        {
            var l = new Label(); l.Text = C.APP.ToUpper();
            l.ForeColor = Color.White; l.BackColor = Color.FromArgb(0x1b, 0x2a, 0x7a);
            l.Font = new Font("Segoe UI", 16, FontStyle.Bold);
            l.Dock = DockStyle.Left; l.Width = 260; l.TextAlign = ContentAlignment.MiddleLeft;
            hd.Controls.Add(l);
        }
        kp = new Label();
        kp.Dock = DockStyle.Right; kp.Width = 320;
        kp.ForeColor = Color.FromArgb(0xcf, 0xd4, 0xff); kp.BackColor = Color.FromArgb(0x1b, 0x2a, 0x7a);
        kp.TextAlign = ContentAlignment.MiddleRight; kp.Font = C.FONT;
        hd.Controls.Add(kp);

        var barTlp = new TableLayoutPanel();
        barTlp.Dock = DockStyle.Top; barTlp.Height = 110; barTlp.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        var items = new List<object[]> {
            new object[] { "Nouvelle r\u00E9ception", (Action<App>)(a => new NewRec(a).Show()) },
            new object[] { "Qualification", (Action<App>)(a => a.OpenQ()) },
            new object[] { "Consultation des stocks", (Action<App>)(a => new Consult(a).Show()) },
            new object[] { "Commandes OF", (Action<App>)(a => new Commandes(a).Show()) },
            new object[] { "Picking", (Action<App>)(a => new Picking(a).Show()) },
            new object[] { "Inventaire", (Action<App>)(a => new Inventaire(a).Show()) },
            new object[] { "Tiers", (Action<App>)(a => new Tiers(a).Show()) },
            new object[] { "Historique", (Action<App>)(a => new Histo(a).Show()) },
            new object[] { "Imprimante Zebra", (Action<App>)(a => new ZebraSet(a).Show()) },
            new object[] { "Retour Laboratoire", (Action<App>)(a => new RetourLabo(a).Show()) },
            new object[] { "Simulation OF", (Action<App>)(a => new SimOF(a).Show()) },
            new object[] { "Sortie mati\u00E8re OF", (Action<App>)(a => new SortieOF(a).Show()) },
            new object[] { "Fabrication du L", (Action<App>)(a => new FabL(a).Show()) },
            new object[] { "Transfert Sortie", (Action<App>)(a => new Transfert(a).Show()) },
            new object[] { "Regroupement Fourn.", (Action<App>)(a => new RegroupFourn(a).Show()) },
            new object[] { "Picking Fournitures", (Action<App>)(a => new SortiePickFourn(a).Show()) },
            new object[] { "Fiche Mod\u00E8le", (Action<App>)(a => new ModeleFiche(a).Show()) },
            new object[] { "Param Tests Labo", (Action<App>)(a => new ParamTests(a).Show()) },
            new object[] { "M.A.J Liste \u00E0 servir", (Action<App>)(a => new MAJListe(a).Show()) },
            new object[] { "Stock Secondaire", (Action<App>)(a => new StockSec(a).Show()) },
            new object[] { "Laboratoire \u2696", (Action<App>)(a => new Laboratoire(a).Show()) },
            new object[] { "Assistant IA \uD83E\uDDE0", (Action<App>)(a => new AIDlg(a).Show()) },
            new object[] { "Liste r\u00E9ceptions", (Action<App>)(a => a.OpenList()) }};
        barTlp.ColumnCount = 6;
        for (int i = 0; i < items.Count; i++)
        {
            Action<App> op = (Action<App>)items[i][1];
            string t = (string)items[i][0];
            var b = UI.Btn(t, delegate
            {
                try { op(this); }
                catch (ValueError v) { U.Warn(this, v.Message); }
            }, false, 21);
            b.Margin = new Padding(4, 3, 4, 3);
            barTlp.Controls.Add(b, i % 6, i / 6);
        }
        Controls.Add(body);
        Controls.Add(barTlp);
        Controls.Add(hd);
        Refresh();
    }

    public void OpenList()
    {
        if (listWin != null && !listWin.IsDisposed) { listWin.Activate(); return; }
        listWin = new Form();
        listWin.Text = C.APP + " \u2013 R\u00E9ceptions";
        listWin.ClientSize = new Size(1000, 500);
        listWin.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        g = new Grid(listWin, new[] { "N\u00B0", "Date", "Libell\u00E9", "Transporteur", "Colis ann. / re\u00E7us", "Lignes", "\u00C9tiquettes", "Statut" },
                     new[] { 110, 90, 260, 120, 120, 60, 80, 100 }, 14, null, delegate { OpenQ(); }, null);
        g.Dock = DockStyle.Fill;
        var pnl = new Panel(); pnl.Dock = DockStyle.Bottom; pnl.Height = 42; pnl.BackColor = Color.FromArgb(0xf0, 0xf0, 0xf0);
        var b = UI.Btn("Supprimer la r\u00E9ception", delegate { Rm(); }, true, 24);
        b.Location = new Point(1000 - (24 * 7 + 14) - 12, 4); b.Anchor = AnchorStyles.Right;
        pnl.Controls.Add(b);
        listWin.Controls.Add(g);
        listWin.Controls.Add(pnl);
        listWin.FormClosed += delegate { listWin = null; g = null; };
        listWin.Show(this);
        Refresh();
    }

    public void OpenQ()
    {
        if (g != null && g.Cur != null)
            new Qualif(this, g.Cur).Show();
        else
            U.Info(this, "S\u00E9lectionnez d'abord une r\u00E9ception dans la liste.");
    }

    void Rm()
    {
        if (g == null || g.Cur == null) return;
        if (U.Ask(this, "Supprimer la r\u00E9ception " + g.Cur + " ?"))
        {
            try { S.DelRec(g.Cur); }
            catch (ValueError e) { U.Warn(this, e.Message); }
            Refresh();
        }
    }

    public new void Refresh()
    {
        if (g != null && !g.IsDisposed && listWin != null && !listWin.IsDisposed)
        {
            var rows = new List<GRow>();
            try
            {
                foreach (Row r in S.Q("SELECT * FROM rec ORDER BY id DESC"))
                {
                    List<Row> n = S.Q("SELECT COUNT(*) c, SUM(st IN ('LOGIQUE','SORTI')) k FROM eti WHERE rec=?", r.S("id"));
                    bool ok = n[0].L("c") != 0 && n[0].L("k") == n[0].L("c");
                    rows.Add(new GRow(r.S("id"),
                        new[] { r.S("id"), r.S("date"), r.S("lb"), r.S("tr"), r.D("ca") + " / " + r.D("cr"),
                                S.Q("SELECT COUNT(*) c FROM lig WHERE rec=?", r.S("id"))[0].S("c"),
                                n[0].S("c"), ok ? "EN STOCK" : "EN COURS" }, false));
                }
                g.Fill(rows);
            }
            catch { }
        }
        if (kp == null) return;
        try
        {
            List<Row> c = S.Q("SELECT SUM(st IN ('NRECEP','RECEP','LABOET','LABOFT')) a, SUM(st='LOGIQUE') b FROM eti");
            kp.Text = (c[0].L("a") > 0 ? c[0].L("a") : 0) + " \u00E9tiquette(s) en r\u00E9ception / labo\n"
                    + (c[0].L("b") > 0 ? c[0].L("b") : 0) + " \u00E9tiquette(s) en stock";
        }
        catch { }
    }

    // ex\u00E9cute une action quand la fen\u00EAtre est pr\u00EAte (remplace root.after(400, ...))
    public void ActivateDelayed(Action act)
    {
        var t = new System.Windows.Forms.Timer();
        t.Interval = 250;
        t.Tick += delegate
        {
            t.Stop(); t.Dispose();
            try { act(); } catch { }
        };
        t.Start();
    }
}

public class Program
{
    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Store S = new Store(null);
        try
        {
            PortalServer.Current = new PortalServer(S);
            PortalServer.Current.Start();
        }
        catch { PortalServer.Current = null; }
        var ctx = new ApplicationContext();
        var start = new StartScreen(S, ctx);
        ctx.MainForm = start;
        Application.Run(ctx);
    }
}
}
'@

Write-Host 'Compilation de Pro Textile Système 1 (C# WinForms)...' -ForegroundColor Cyan
$refs = @('System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','Microsoft.CSharp.dll')
try {
    Add-Type -TypeDefinition $cs -ReferencedAssemblies $refs -Language CSharp -ErrorAction Stop
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.InnerException) { Write-Host $_.Exception.InnerException.Message -ForegroundColor Red }
    exit 1
}
Write-Host 'OK.' -ForegroundColor Green
[PTS.Program]::Main()
