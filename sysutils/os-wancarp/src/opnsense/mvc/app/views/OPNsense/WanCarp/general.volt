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

<div class="alert alert-warning" role="alert">
    <b>{{ lang._('Routing requirement - both firewalls') }}</b><br/>
    {{ lang._('Because only the MASTER firewall has an active WAN interface, the BACKUP firewall must route all traffic through the MASTER. Static routes must be configured on BOTH nodes.') }}
    <hr style="margin: 0.5em 0;"/>
    <b>{{ lang._('IPv4') }}</b><br/>
    {{ lang._('Set the default gateway (0.0.0.0/0) to the shared LAN-side CARP VIP on both firewalls.') }}<br/>
    <small><i>{{ lang._('System - Gateways - Configuration - select the LAN CARP VIP gateway') }}</i></small>
    <hr style="margin: 0.5em 0;"/>
    <b>{{ lang._('IPv6') }}</b><br/>
    {{ lang._('Due to a FreeBSD CARP limitation, IPv6 routing does NOT follow the CARP VIP. Set the default IPv6 route on each firewall to the link-local address of the peer LAN interface:') }}
    <ul style="margin: 0.4em 0 0 1.2em;">
        <li>{{ lang._('FW1: default IPv6 GW = link-local address of FW2 LAN interface') }}</li>
        <li>{{ lang._('FW2: default IPv6 GW = link-local address of FW1 LAN interface') }}</li>
    </ul>
    <small><i>{{ lang._('System - Gateways - Configuration - add a static gateway per peer using its fe80:: address and LAN interface') }}</i></small><br/>
    <small>{{ lang._('Background: a CARP VIP as IPv6 GW causes the BACKUP node to lose its default route after failover because the neighbour cache entry goes stale. Link-local addresses are always reachable on the LAN segment regardless of CARP state.') }}</small>
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
    // Initialize selectpicker BEFORE loading data so setFormData can refresh it
    $('.selectpicker').selectpicker();

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

