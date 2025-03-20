from . import models


def post_init_hook(cr, registry):
    """Change the 'Generate Leads' button text to 'Generate Happiness'"""
    from odoo import api, SUPERUSER_ID

    env = api.Environment(cr, SUPERUSER_ID, {})
    menus = env["ir.ui.menu"].search([("name", "=", "Generate Leads")])
    if menus:
        menus.write({"name": "Generate Happiness"})
