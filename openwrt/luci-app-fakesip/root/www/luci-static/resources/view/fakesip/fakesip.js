'use strict';
'require view';
'require form';
'require fs';
'require ui';

function serviceCommand(action) {
	return fs.exec('/etc/init.d/fakesip', [ action ]).then(function(res) {
		if (res.code === 0) {
			ui.addNotification(null, E('p', _('Service command completed.')));
			window.setTimeout(function() {
				window.location.reload();
			}, 800);
		}
		else {
			ui.addNotification(null, E('p', _('Service command failed: %s').format(res.stderr || res.stdout || res.code)));
		}
	}).catch(function(err) {
		ui.addNotification(null, E('p', _('Service command failed: %s').format(err.message)));
	});
}

function actionButton(label, action, cssClass) {
	return E('button', {
		'class': 'btn cbi-button %s'.format(cssClass || 'cbi-button-action'),
		'click': function(ev) {
			ev.preventDefault();
			return serviceCommand(action);
		}
	}, label);
}

function statusText(output) {
	if (!output)
		return _('Unknown');

	if (output.match(/running/i))
		return _('Running');

	if (output.match(/inactive|stopped|not running/i))
		return _('Stopped');

	return output.trim();
}

return view.extend({
	load: function() {
		return L.resolveDefault(fs.exec_direct('/etc/init.d/fakesip', [ 'status' ]), '');
	},

	render: function(statusOutput) {
		var m, s, o, statusPanel;

		statusPanel = E('div', { 'class': 'cbi-section' }, [
			E('h3', _('FakeSIP')),
			E('p', {}, [
				E('strong', _('Status')),
				': ',
				statusText(statusOutput)
			]),
			E('p', { 'class': 'cbi-section-actions' }, [
				actionButton(_('Start'), 'start', 'cbi-button-apply'),
				' ',
				actionButton(_('Stop'), 'stop', 'cbi-button-remove'),
				' ',
				actionButton(_('Restart'), 'restart', 'cbi-button-reload')
			])
		]);

		m = new form.Map('fakesip', _('FakeSIP'),
			_('Disguise UDP traffic as SIP protocol traffic using Netfilter Queue.'));

		s = m.section(form.TypedSection, 'fakesip', _('Instances'));
		s.addremove = true;
		s.anonymous = false;
		s.addbtntitle = _('Add instance');

		s.tab('basic', _('Basic'));
		s.tab('traffic', _('Traffic'));
		s.tab('advanced', _('Advanced'));
		s.tab('payload', _('Payload'));

		o = s.taboption('basic', form.Flag, 'enabled', _('Enabled'));
		o.default = '0';

		o = s.taboption('basic', form.DynamicList, 'network', _('OpenWrt networks'));
		o.placeholder = 'wan';
		o.rmempty = true;

		o = s.taboption('basic', form.DynamicList, 'interface', _('Linux interfaces'));
		o.placeholder = 'pppoe-wan';
		o.rmempty = true;

		o = s.taboption('basic', form.Flag, 'all_interfaces', _('All interfaces'));
		o.default = '0';

		o = s.taboption('traffic', form.Flag, 'outbound', _('Outbound traffic'));
		o.default = '1';

		o = s.taboption('traffic', form.Flag, 'inbound', _('Inbound traffic'));
		o.default = '0';

		o = s.taboption('traffic', form.Flag, 'ipv4', _('IPv4'));
		o.default = '1';

		o = s.taboption('traffic', form.Flag, 'ipv6', _('IPv6'));
		o.default = '1';

		o = s.taboption('advanced', form.Value, 'queue_num', _('NFQUEUE number'));
		o.datatype = 'range(1,4294967295)';
		o.placeholder = '513';

		o = s.taboption('advanced', form.Value, 'fwmark', _('Firewall mark'));
		o.placeholder = '0x10000';

		o = s.taboption('advanced', form.Value, 'fwmask', _('Firewall mark mask'));
		o.placeholder = '0x10000';

		o = s.taboption('advanced', form.Value, 'repeat', _('Fake packet repeats'));
		o.datatype = 'range(1,10)';
		o.placeholder = '2';

		o = s.taboption('advanced', form.Value, 'ttl', _('Fake packet TTL'));
		o.datatype = 'range(1,255)';
		o.placeholder = '3';

		o = s.taboption('advanced', form.Value, 'dynamic_pct', _('Dynamic TTL percent'));
		o.datatype = 'range(0,99)';
		o.placeholder = '0';

		o = s.taboption('advanced', form.Flag, 'no_hop_estimate', _('Disable hop estimation'));
		o.default = '0';

		o = s.taboption('advanced', form.Flag, 'skip_firewall', _('Skip firewall rules'));
		o.default = '0';

		o = s.taboption('advanced', form.Flag, 'use_iptables', _('Use iptables instead of nft'));
		o.default = '0';

		o = s.taboption('advanced', form.Flag, 'silent', _('Silent mode'));
		o.default = '1';

		o = s.taboption('advanced', form.Value, 'log_file', _('Log file'));
		o.placeholder = '/tmp/fakesip.log';
		o.rmempty = true;

		o = s.taboption('payload', form.DynamicList, 'sip_uri', _('SIP URI'));
		o.placeholder = 'sip:10086@example.com';
		o.rmempty = true;

		o = s.taboption('payload', form.DynamicList, 'payload_file', _('Payload file'));
		o.placeholder = '/etc/fakesip/payload.bin';
		o.rmempty = true;

		return m.render().then(function(node) {
			node.insertBefore(statusPanel, node.firstChild);
			return node;
		});
	}
});
