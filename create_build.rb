#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'optimist'

def spinner(fps = 10)
  spinny_chars = %w[| / - \\]
  delay = 1.0 / fps
  iter = 0
  spinner = Thread.new do
    while iter
      print spinny_chars[(iter += 1) % spinny_chars.length]
      sleep delay
      print "\b"
    end
  end
  yield.tap do
    iter = false
    spinner.join
  end
end

opts = Optimist.options do
  opt :repo, 'the git repository to build from', type: :string, default: 'https://github.com/RedHatInsights/catalog-api'
  opt :branch, 'push after building', default: 'master'
end

spinner { sleep rand(1..4) }
puts "creating buildconfig for #{opts[:repo]}##{opts[:branch]}"
`oc import-image --confirm quay.io/jlindgren/catalog-api-base`
`cat Dockerfile.dev | oc new-build #{opts[:repo]}##{opts[:branch]} --dockerfile -`
`oc patch bc/catalog-api --patch "$(cat configs/bc_patch.json)"`
`oc cancel-build bc/catalog-api && oc start-build bc/catalog-api`
