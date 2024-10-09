project_name: "dpa"

# # Use local_dependency: To enable referencing of another project
# # on this instance with include: statements
#
# local_dependency: {
#   project: "name_of_other_project"
# }

#
application: dpa {
  label: "Data Portrait Analysis"
  url: "http://localhost:8080/bundle.js"
  # file: "apps/bundle.js"
  entitlements: {
    local_storage: yes
    navigation: yes
    new_window: yes
    use_form_submit: yes
    use_embeds: yes
    core_api_methods:
    ["all_connections",
      "me",
      "query",
      "run_query",
      "run_inline_query",
      "create_query"]
    external_api_urls:
    ["http://127.0.0.1:3000",
      "http://localhost:3000",
      "https://*.googleapis.com",
      "https://*.github.com",
      "https://REPLACE_ME.auth0.com",
      "http://localhost:8080",
      "https://localhost:8080"]
    oauth2_urls:
    ["https://accounts.google.com/o/oauth2/v2/auth",
      "https://github.com/login/oauth/authorize",
      "https://dev-5eqts7im.auth0.com/authorize",
      "https://dev-5eqts7im.auth0.com/login/oauth/token",
      "https://github.com/login/oauth/access_token"]
    scoped_user_attributes: ["user_value"]
    global_user_attributes: ["locale"]
    use_iframes: yes
    new_window_external_urls: ["https://docs.looker.com/*", "https://github.com/*"]
    use_clipboard: yes

  }
}
