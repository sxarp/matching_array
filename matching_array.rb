require 'yaml'
require 'fileutils'
require 'forwardable'
require 'pry'

class MatchingArray
  # Arrayから必要なメソッドだけつまみたいので移譲パターンを使います
  extend(Forwardable)
  def_delegators(:@array, :map!, :compact!, :delete, :select)
  def_delegator(:@array, :inspect, :to_s)

  def initialize(array)
    @array = Array.new(array)
    self
  end

  # 自分と相手の持つ要素達から条件を満たすペアを取り出します
  def match(another_matching_array)
    matched_items = []
    map! do |item|
      matched_another_item = another_matching_array.find_and_pop do |another_item|
        yield(item, another_item)
      end
      pop_and_push(item, matched_items, matched_another_item)
    end.delete(:matched_then_deleted)
    matched_items
  end

  protected

  def pop_and_push(item, matched_items, matched_another_item)
    if matched_another_item
      matched_items << [item, matched_another_item]
      :matched_then_deleted
    else
      item
    end
  end

  # 条件にマッチした要素を一つ見つけ、popします
  def find_and_pop
    items = select { |item| yield item }
    # 厳密な一対一対応をさせたいので、複数の要素が条件にマッチするときには例外を投げます
    raise MultipleItemsMatchError.new(items[0], items[1]) if items.length > 1
    matched_item = items.first
    delete(matched_item)
    matched_item
  end
end

class MultipleItemsMatchError < StandardError
  attr_accessor :item1, :item2
  def initialize(matched_item1, matched_item2)
    @item1 = matched_item1
    @item2 = matched_item2
    super("Matched multileple items!: \n#{matched_item1.inspect}\n#{matched_item2.inspect}")
  end
end

# 簡単な使用例

original_array = (1..10).to_a

num_array = MatchingArray.new(original_array.map { |num| 2 * num })
puts "数字の入った配列: #{num_array}"

str_array = MatchingArray.new(original_array.map(&:to_s))
puts "文字列の入った配列: #{str_array}"

# matchを使ったペアの抽出
matched_pairs = num_array.match(str_array) do |num, str|
  num.to_s == str
end

puts "{ num.to_s == str }の条件でマッチしたペア: #{matched_pairs}"

puts "抽出後の数字の入った配列: #{num_array}"
puts "抽出後の文字列の入った配列: #{str_array}"
