provider "aci" {
    username = ""
    password = ""
    url      = ""
    insecure = true
}

resource "aci_tenant" "aci_p26_tenant" {
    name             = "aci_p26_tenant"
  }

  resource "aci_vrf" "aci_p26_vrf" {
    tenant_dn         = aci_tenant.aci_p26_tenant.id
    name              = "aci_p26_vrf"
  }

  resource "aci_bridge_domain" "aci_p26_bd_web" {
    tenant_dn              = aci_tenant.aci_p26_tenant.id
    relation_fv_rs_ctx    = aci_vrf.aci_p26_vrf.id
    name                  = "aci_p26_bd_web"
  }

  resource "aci_subnet" "web_subnet" {
    bridge_domain_dn     = aci_bridge_domain.aci_p26_bd_web.id
    ip                   = local.web_bd_ip
  }

  resource "aci_bridge_domain" "aci_p26_bd_app" {
    tenant_dn             = aci_tenant.aci_p26_tenant.id
    relation_fv_rs_ctx    = aci_vrf.aci_p26_vrf.id
    name                  = "aci_p26_bd_app"
  }

  resource "aci_subnet" "app_subnet" {
    bridge_domain_dn     = aci_bridge_domain.aci_p26_bd_app.id
    ip                   = local.app_bd_ip
  }

  resource "aci_application_profile" "aci_p26_ap" {
    tenant_dn         = aci_tenant.aci_p26_tenant.id
    name              = "aci_p26_ap"
  }

  data "aci_vmm_domain" "aci_p26_dc3_vds" {
    provider_profile_dn     = "/uni/vmmp-VMware"
    name                     = "aci_p26_dc3_vds"
  }

  resource "aci_contract" "aci_p26_con" {
   tenant_dn                 = aci_tenant.aci_p26_tenant.id
   name                        = "aci_p26_con"
  }

  resource "aci_contract_subject" "aci_p26_sub" {
    contract_dn                  = aci_contract.aci_p26_con.id
    name                         = "aci_p26_sub"
    relation_vz_rs_subj_filt_att = [aci_filter.allow_icmp.id]
  }

  resource "aci_filter" "allow_icmp" {
    tenant_dn = aci_tenant.aci_p26_tenant.id
    name      = "allow_icmp"
  }

  resource "aci_filter_entry" "icmp" {
    name        = "icmp"
    filter_dn   = aci_filter.allow_icmp.id
    ether_t     = "ip"
    prot        = "icmp"
    stateful    = "yes"
  }


  resource "aci_application_epg" "aci_p26_epg_web" {
    application_profile_dn  = aci_application_profile.aci_p26_ap.id
    name                    = "aci_p26_epg_web"
    relation_fv_rs_bd       = aci_bridge_domain.aci_p26_bd_web.id
    relation_fv_rs_dom_att  = [data.aci_vmm_domain.aci_p26_dc3_vds.id]
    relation_fv_rs_cons     = [aci_contract.aci_p26_con.id]
  }

  resource "aci_application_epg" "aci_p26_epg_app" {
    application_profile_dn  = aci_application_profile.aci_p26_ap.id
    name                    = "aci_p26_epg_app"
    relation_fv_rs_bd       = aci_bridge_domain.aci_p26_bd_app.id
    relation_fv_rs_dom_att  = [data.aci_vmm_domain.aci_p26_dc3_vds.id]
    relation_fv_rs_prov     = [aci_contract.aci_p26_con.id]
  }
