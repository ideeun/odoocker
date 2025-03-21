odoo.define("crm_field_rename.hawk_button", function (require) {
  "use strict";

  var core = require("web.core");
  var ListView = require("web.ListView");
  var KanbanView = require("web.KanbanView");

  // Add Hawk Tuah button to list view
  ListView.include({
    renderButtons: function () {
      this._super.apply(this, arguments);
      if (this.modelName === "crm.lead") {
        var $hawkButton = $(
          '<button class="btn btn-primary" type="button">Hawk Tuah</button>'
        );
        this.$buttons.find(".o_list_button_add").after($hawkButton);

        $hawkButton.on("click", this._onHawkButtonClick.bind(this));
      }
    },

    _onHawkButtonClick: function (ev) {
      ev.preventDefault();
      alert("Hawk Tuah button clicked!");
      // You can add more functionality here
    },
  });

  // Add Hawk Tuah button to kanban view
  KanbanView.include({
    renderButtons: function () {
      this._super.apply(this, arguments);
      if (this.modelName === "crm.lead") {
        var $hawkButton = $(
          '<button class="btn btn-primary" type="button">Hawk Tuah</button>'
        );
        this.$buttons.find(".o-kanban-button-new").after($hawkButton);

        $hawkButton.on("click", this._onHawkButtonClick.bind(this));
      }
    },

    _onHawkButtonClick: function (ev) {
      ev.preventDefault();
      alert("Hawk Tuah button clicked!");
      // You can add more functionality here
    },
  });
});
