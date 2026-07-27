module ContentFactory
  class SlideshowCreator
    class Error < StandardError; end

    DRAFT_BATCH_SIZE = 2
    DRAFT_BATCH_INTERVAL = 1.hour

    ANGLES_BY_PILLAR = {
      "beginner study tips" => [
        "active recall after studying", "spaced repetition schedule", "the Feynman explanation method",
        "the 80/20 rule for revision", "turning notes into questions", "how to start a difficult study session",
        "a focused 30-minute study block", "remembering formulas with worked examples", "the best order for revising topics",
        "how to review a lecture within 24 hours", "using practice questions effectively", "breaking a large assignment into first steps"
      ],
      "common study mistakes" => [
        "re-reading notes instead of retrieving", "highlighting without testing yourself", "watching lectures passively",
        "cramming the night before", "studying with constant notifications", "rewriting notes word for word",
        "using flashcards without recall", "switching subjects too often", "studying for hours without breaks",
        "starting revision without a plan", "avoiding practice questions", "mistaking familiarity for knowledge"
      ],
      "daily study routines" => [
        "a five-minute post-lecture review", "a realistic 30-minute evening routine", "a Sunday study reset",
        "planning tomorrow before ending today", "a pre-exam morning routine", "a wind-down routine after studying",
        "a first 10 minutes routine for procrastination", "weekly review of weak topics", "a routine for busy class days",
        "a short routine before starting homework", "how to reset after missing a study day", "a routine for organizing course material"
      ],
      "academynote in action" => [
        "turning lecture notes into flashcards", "making a quiz from homework", "summarising a PDF before revision",
        "building an exam revision plan", "finding weak areas with practice quizzes", "turning a chapter into key points",
        "creating questions from class notes", "organising notes by subject", "using an AI summary before active recall",
        "planning revision from an exam date", "turning a study guide into a checklist", "reviewing a difficult topic with a quiz"
      ]
    }.freeze

    HOOK_STYLES = [
      "curiosity", "myth-bust", "checklist", "challenge", "before-and-after", "practical promise"
    ].freeze

    def initialize(project, zernio_account:, factory_date: Time.zone.today, factory_slot: 1)
      @project = project
      @zernio_account = zernio_account
      @factory_date = factory_date.to_date
      @factory_slot = factory_slot
    end

    def call
      return @project.slideshows.find_by(zernio_account: @zernio_account, factory_date: @factory_date, factory_slot: @factory_slot) if @project.slideshows.exists?(zernio_account: @zernio_account, factory_date: @factory_date, factory_slot: @factory_slot)
      raise Error, "#{@zernio_account.label} needs a content strategy and content pillars." unless @zernio_account.factory_configured?

      slideshow = ContentTopic.transaction do
        pillar = next_pillar
        topic = @project.content_topics.create!(
          pillar:,
          angle: next_angle(pillar),
          hook_style: next_hook_style,
          zernio_account: @zernio_account,
          daily_slot: @factory_slot,
          scheduled_for: @factory_date,
          status: :generating
        )
        slideshow = @project.user.slideshows.build(
          project: @project,
          content_topic: topic,
          prompt: prompt_for(topic),
          slide_count: @project.default_slide_count,
          delivery_mode: "tiktok_draft",
          first_delivery_at: delivery_at,
          factory_date: @factory_date,
          factory_slot: @factory_slot,
          zernio_account: @zernio_account,
          status: :generating
        )
        slideshow.zernio_accounts = target_accounts
        slideshow.save!
        topic.update!(slideshow:)
        slideshow
      end
      TikTok::ProcessSlideshowJob.perform_later(slideshow)
      slideshow
    end

    private
      def target_accounts
        [ @zernio_account ]
      end

      def next_pillar
        pillars = @zernio_account.profile_content_pillars.map(&:strip).reject(&:blank?)
        usage = account_topics.group(:pillar).count
        pillars.min_by { |pillar| usage.fetch(pillar, 0).fdiv(@zernio_account.profile_pillar_weight(pillar)) }
      end

      def next_angle(pillar)
        angles = ANGLES_BY_PILLAR.fetch(pillar.to_s.downcase, generic_angles_for(pillar))
        recent_angles = account_topics.where(pillar:).order(created_at: :desc).limit(30).pluck(:angle).compact
        eligible_angles = angles - recent_angles
        candidates = eligible_angles.presence || angles
        usage = account_topics.where(pillar:, angle: candidates).group(:angle).count
        candidates.min_by { |angle| [ usage.fetch(angle, 0), angle ] }
      end

      def next_hook_style
        recent_styles = account_topics.order(created_at: :desc).limit(3).pluck(:hook_style).compact
        candidates = HOOK_STYLES - recent_styles
        usage = account_topics.where(hook_style: candidates).group(:hook_style).count
        candidates.min_by { |style| [ usage.fetch(style, 0), style ] }
      end

      def generic_angles_for(pillar)
        [
          "the first step to improve #{pillar.downcase}", "a simple #{pillar.downcase} checklist",
          "a common obstacle in #{pillar.downcase}", "a quick win for #{pillar.downcase}",
          "a better way to plan #{pillar.downcase}", "how to make #{pillar.downcase} easier",
          "a realistic routine for #{pillar.downcase}", "one question to improve #{pillar.downcase}"
        ]
      end

      def delivery_at
        batch_number = (@factory_slot - 1) / DRAFT_BATCH_SIZE
        @project.time_zone_object.parse("#{@factory_date} #{@project.factory_time}") + batch_number * DRAFT_BATCH_INTERVAL
      end

      def prompt_for(topic)
        recent_topics = account_topics.order(created_at: :desc).limit(20).where.not(id: topic.id)
        recent_titles = recent_topics.where.not(title: nil).pluck(:title)
        recent_angles = recent_topics.where.not(angle: nil).pluck(:angle)
        <<~PROMPT.squish
          Create a fresh TikTok slideshow for this content factory.
          Account audience: #{@zernio_account.label}.
          Strategy: #{@zernio_account.profile_content_strategy}
          Today's pillar: #{topic.pillar}.
          Required angle: #{topic.angle}.
          Required hook style: #{topic.hook_style}.
          Teach the required angle only; do not substitute a different study technique or mistake.
          Do not repeat or closely mirror these recent titles: #{recent_titles.presence || "none yet"}.
          Do not repeat these recently used angles: #{recent_angles.presence || "none yet"}.
          Prioritize practical value, accuracy, and a clear audience fit.
        PROMPT
      end

      def account_topics = @zernio_account.content_topics
  end
end
