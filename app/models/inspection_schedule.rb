class InspectionSchedule < ActiveRecord::Base
  belongs_to :equipment
  belongs_to :status
  belongs_to :user
  belongs_to :result
  has_many :inspection_result
  has_one :approval
  has_many :inspection_requests

  include Common
  after_commit :dump

  # InspectionSchedule上に、1年前以前の情報しかないequipment_idの一覧を取得。
  # TODO: 点検周期を過ぎた情報にする equipment_id にする必要があるはず。
  def self.old_inspection_equipment_list
    limit_date = Time.now.prev_year
    InspectionSchedule.select("equipment_id, max(targetyearmonth) ")
              .group("equipment_id")
              .having("max(targetyearmonth) < '#{limit_date.strftime('%Y%m')}'")
              .pluck(:equipment_id)
  end

  # 装置システムの点検予定をまとめて作成
  def self.bulk_create(params, current_date)
    params.targets.try(:map) do |equipment_id|
      if User.exists?(id: params.user_id)
        new_inspection_schedule = new(
          targetyearmonth: params.targetyearmonth,
          equipment_id: equipment_id,
          status_id: 1,
          user_id: params.user_id,
          result_id: 4,
          processingdate: current_date
        )
        new_inspection_schedule.save
      else
        false
      end
    end
  end

  # InspectionSchedule のステータス変更
  def start_inspection
    self.status_id = Status.of_doing;
  end
  def close_inspection
    self.status_id = Status.of_done;
    self.processingdate = currentDate
  end

# Inspection の結果変更
  def judging(inspection_result)
    if(inspection_result.check.tone_id!=4)
      self.result_id = Result.of_ok;
    else
      self.result_id = Result.of_ng;
    end
    self.processingdate = currentDate
  end

# 点検中(doing)かどうか
  def doing?
    if self.status.id == Status.of_doing
      true
    else
      false
    end
  end

# 完了している状態かどうか
  def close?
    if self.status.id == Status.of_done
      true
    else
      false
    end
  end

# 点検開始して良いかどうか
  def can_inspection?
    if self.status.id == Status.of_done
      false # 完了 してたらダメ
    else
      true # 完了してなければ良い（とりあえず）
    end
  end

end
