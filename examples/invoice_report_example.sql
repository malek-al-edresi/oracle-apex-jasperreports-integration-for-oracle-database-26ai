-- ══════════════════════════════════════════════════════════════
-- Example: Generate Invoice Report
-- ══════════════════════════════════════════════════════════════

-- ── From APEX Page Process (Before Header) ──────────────────
BEGIN
    jasper_report_pkg.get_report(
        p_settings_id     => 1,
        p_file_base_name  => 'invoice_report',
        p_file_type       => 'pdf',
        p_param_name      => 'P_INVOICE_ID',
        p_param_value     => :P2_INVOICE_ID,
        p_output_filename => 'Invoice_' || :P2_INVOICE_ID
    );
END;
/

-- ── Print invoice as inline PDF (view in browser) ───────────
-- Set CONTENT_DISPOSITION to 'inline' in REPORT_SETTINGS
-- or create a separate settings row for inline viewing.
