return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose' },
  root_markers = { '.git' },
  settings = {
    yaml = {
      schemas = {
        ['https://s3.amazonaws.com/cfn-resource-specifications-us-east-1-prod/schemas/2.15.0/all-spec.json'] = '~/source/github.com/einwert/infrastructure',
      },
      customTags = {
        '!fn',
        '!And',
        '!If',
        '!Not',
        '!Equals',
        '!Or',
        '!FindInMap sequence',
        '!Base64',
        '!Cidr',
        '!Ref',
        '!Ref Scalar',
        '!Sub',
        '!Sub sequence',
        '!GetAtt',
        '!GetAZs',
        '!ImportValue',
        '!Select',
        '!Split',
        '!Join sequence',
      },
    },
  },
}
