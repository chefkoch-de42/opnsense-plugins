{#
Copyright (C) 2024 Your Name
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
#}

<div class="alert alert-info" role="alert">
    <b>{{ lang._('WAN CARP Hook') }}</b><br/>
    {{ lang._('This plugin automatically enables the selected WAN interface when this node becomes CARP MASTER, and disables it when it becomes BACKUP. Configure the VHID of your LAN/sync CARP VIP that triggers the failover.') }}
</div>

<div class="col-md-12">
    {{ partial("layout_partials/base_form", ['fields': generalForm, 'id': 'frm_general_settings']) }}
</div>

<div class="col-md-12">
    <hr/>
    <button class="btn btn-primary" id="saveAct" type="button">
        <b>{{ lang._('Save') }}</b>
        <i id="saveAct_progress"></i>
    </button>
</div>

<script>
$(function () {
    mapDataToFormUI({'frm_general_settings': "/api/wancarp/general/get"}).done(function (data) {
        formatTokenizersUI();
        $('.selectpicker').selectpicker('refresh');
    });

    $("#saveAct").click(function () {
        saveFormToEndpoint(
            url = "/api/wancarp/general/set",
            formid = 'frm_general_settings',
            callback_ok = function () {
                $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
                // No daemon to reconfigure, just acknowledge save
                $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
            }
        );
    });
});
</script>

