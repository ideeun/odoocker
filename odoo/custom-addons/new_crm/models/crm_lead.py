from odoo import models, fields, api


class Lead(models.Model):
    _inherit = "crm.lead"

    # Поле для отслеживания, находится ли лид в общем пуле
    is_pool_lead = fields.Boolean(string="В общем пуле", default=True)

    @api.model  # Используем @api.model, так как метод работает с одной записью
    def action_claim_lead(self):
        """При нажатии на кнопку лид закрепляется за текущим пользователем"""
        for lead in self:
            lead.is_pool_lead = False  # Закрепляем лид
            lead.user_id = self.env.user  # Назначаем текущего пользователя
