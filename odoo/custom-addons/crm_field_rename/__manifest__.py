{
    "name": "CRM Field Rename",
    "version": "1.0",
    "category": "Sales/CRM",
    "summary": "Rename CRM fields",
    "description": """
        This module renames the 'Generate leads' field to 'Generate happiness' in CRM.
    """,
    "author": "Odoocker",
    "website": "https://odoocker.com",
    "depends": ["crm"],
    "data": [
        "views/crm_views.xml",
    ],
    "installable": True,
    "application": False,
    "auto_install": False,
    "license": "LGPL-3",
}
