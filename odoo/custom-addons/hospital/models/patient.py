from odoo import api, fields, models


class HospitalPatient(models.Model):
    _name = "hospital.patient"
    _description = "Hospital Patient"

    name = fields.Char(string="Name", required=True)
    date_of_birth = fields.Date(string="Date of Birth")
    genter = fields.Selection([("male", "Male"), ("female", "Female")], string="Gender")
