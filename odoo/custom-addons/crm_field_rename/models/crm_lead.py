from odoo import models, fields, api


class CrmLead(models.Model):
    _inherit = "crm.lead"

    type = fields.Selection(
        selection_add=[("lead", "Generate happiness")],
        ondelete={"lead": "set default"},
        default="lead",
    )

    def action_generate_happiness(self):
        # This is a placeholder method - you can implement the actual functionality here
        return True

    def action_hawk(self):
        # This action will be triggered when the Hawk button is clicked
        # You can define what you want it to do here
        return {
            "type": "ir.actions.act_window",
            "name": "Hawk Action",
            "res_model": "crm.lead",
            "view_mode": "form,kanban,tree",
            "target": "current",
        }
