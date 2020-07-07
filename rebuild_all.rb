#!/usr/bin/env ruby
# frozen_string_literal: true

RUNNER = 'oc' # we have to use `oc` because of `start-build`

IMAGES = %w[
  topological-inventory-amazon
  topological-inventory-ansible-tower
  topological-inventory-azure
  topological-inventory-openshift
  topological-inventory-satellite
  topological-inventory-sync
].freeze

NOWAIT = ENV['NOWAIT'] == 'true'

unless `#{RUNNER} config current-context`.match?(/^buildfactory$/)
  raise 'Wrong project, change your oc project to `buildfactory`'
end

def rebuild(images)
  images.each do |build|
    puts "Building #{build}, #{NOWAIT ? 'not waiting for each to complete' : 'waiting for each to complete'}"
    system("oc start-build bc/#{build} #{'--follow --wait' unless NOWAIT}")
  end
end

rebuild(IMAGES)
rebuild(IMAGES.map { |image| image << '-stable' }) if ENV['STABLE'] == 'true'
