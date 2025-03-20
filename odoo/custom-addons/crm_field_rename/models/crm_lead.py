from odoo import models, fields


class CrmLead(models.Model):
    _inherit = "crm.lead"

    # All code related to "generate happiness" has been removed

    type = fields.Selection(
        selection_add=[("lead", "Generate happiness")],
        ondelete={"lead": "set default"},
        default="lead",
    )

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
