from odoo import models, fields, api


class CRMLead(models.Model):
    _inherit = "crm.lead"

    def my_custom_button_action(self):
        """Open new leads view"""
        return {
            "type": "ir.actions.act_window",
            "name": "New Leads",
            "res_model": "crm.lead",
            "view_mode": "tree,form",
            "domain": [("stage_id", "=", 1)],
            "target": "current",
        }
