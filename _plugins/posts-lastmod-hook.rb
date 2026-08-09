#!/usr/bin/env ruby

require 'open3'

# Populate the Chirpy "last modified" field from Git history without adding
# metadata to every existing post.
Jekyll::Hooks.register :posts, :post_init do |post|
  commit_num, status = Open3.capture2(
    'git', 'rev-list', '--count', 'HEAD', '--', post.path
  )

  if status.success? && commit_num.to_i > 1
    lastmod_date, log_status = Open3.capture2(
      'git', 'log', '-1', '--pretty=%ad', '--date=iso', '--', post.path
    )
    post.data['last_modified_at'] = lastmod_date.strip if log_status.success?
  end
end
