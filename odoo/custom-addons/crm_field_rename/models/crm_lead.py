from odoo import models, fields


class CrmLead(models.Model):
    _inherit = "crm.lead"

    type = fields.Selection(
        selection_add=[("lead", "Generate happiness")],
        ondelete={"lead": "set default"},
        default="lead",
    )
