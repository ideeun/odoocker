{
    "name": "My Custom Module",
    "version": "1.0",
    "category": "Custom",
    "summary": "Custom functionality for Odoo",
    "description": """
        This module provides custom functionality for Odoo.
    """,
    "author": "Odoocker",
    "website": "https://odoocker.com",
    "depends": ["base"],
    "data": [
        "views/my_model_views.xml",
    ],
    "assets": {
        "web.assets_backend": [
            "my_custom_module/static/src/js/custom_button.js",
        ],
    },
    "post_init_hook": "post_init_hook",
    "installable": True,
    "application": True,
    "auto_install": False,
    "license": "LGPL-3",
}
