-- ============================================================
-- 从 wande_ai_legacy → wande-ai 初始化矿场数据
-- 运维手动执行：mysql -h... -uroot -p < 01_init_wdpp_discovered_projects.sql
-- 前提：wande_ai_legacy.wdpp_discovered_projects 已载入
-- 依赖：wande-ai.wdpp_discovered_projects 已由 Flyway V20260414002 建好
-- ============================================================

USE `wande-ai`;

TRUNCATE TABLE `wdpp_discovered_projects`;

-- 用 INSERT IGNORE 跳过 legacy 中的重复 source_url（保留首条）
INSERT IGNORE INTO `wdpp_discovered_projects` (
    project_name, region, province, city,
    project_scale, budget_amount, investment_text,
    stage, building_content,
    source_url, source_name, source_category, discovery_keyword, discovery_source,
    ai_evaluation_score, score_demand_match, score_project_scale, score_time_window,
    trust_summary, ai_suggestion, match_reason, matched_features,
    match_grade, mine_category, stage_detail, mine_status,
    verification_status, verification_details, verification_count, verification_score, verification_urls,
    verified, verified_at,
    filter_result, filter_reason, do_not_push, score_penalty, has_new_activity,
    assigned_to, assigned_at,
    feedback_type, feedback_reason, feedback_note, feedback_at,
    bad_reason, good_stage,
    doubted, doubt_reason, doubt_note, doubted_at, doubted_by,
    relationship_score, related_win_cases, battle_info,
    synced_to_lightsail, synced_at, notified,
    create_time, update_time, create_dept, create_by, update_by,
    tenant_id, del_flag
)
SELECT
    LEFT(COALESCE(l.title, '未命名项目'), 500),
    LEFT(l.location, 200),
    LEFT(l.province, 50),
    LEFT(l.city, 50),
    l.investment_amount,
    l.investment_amount,
    LEFT(l.investment_text, 200),
    LEFT(l.stage, 100),
    l.building_content,
    LEFT(l.source_url, 1000),
    LEFT(l.source_name, 200),
    COALESCE(l.source_category, 'project'),
    LEFT(l.discovery_keyword, 500),
    LEFT(l.discovery_source, 100),
    LEAST(COALESCE(l.score_total, 0), 100),
    COALESCE(l.score_business_match, 0),
    COALESCE(l.score_investment, 0),
    COALESCE(l.score_stage, 0),
    l.judgment,
    l.ai_analysis,
    l.match_reason,
    l.matched_features,
    COALESCE(l.match_grade, l.grade),
    COALESCE(l.stage_category, 'unknown'),
    COALESCE(l.stage_detail, ''),
    COALESCE(l.status, 'active'),
    COALESCE(l.verification_status, 'pending'),
    l.verification_details,
    COALESCE(l.verification_count, 0),
    COALESCE(l.verification_score, 0),
    l.verification_urls,
    COALESCE(l.verified, 0),
    l.verified_at,
    COALESCE(l.filter_result, 'clean'),
    l.filter_reason,
    COALESCE(l.do_not_push, 0),
    COALESCE(l.score_penalty, 0),
    COALESCE(l.has_new_activity, 0),
    l.assigned_to, l.assigned_at,
    l.feedback_type, l.feedback_reason, l.feedback_note, l.feedback_at,
    l.bad_reason, l.good_stage,
    COALESCE(l.doubted, 0), l.doubt_reason, l.doubt_note, l.doubted_at, l.doubted_by,
    COALESCE(l.relationship_score, 0), l.related_win_cases, l.battle_info,
    COALESCE(l.synced_to_lightsail, 0), l.synced_at, COALESCE(l.notified, 0),
    COALESCE(l.create_time, NOW()), COALESCE(l.update_time, NOW()),
    l.create_dept, l.create_by, l.update_by,
    '000000', '0'
FROM `wande_ai_legacy`.`wdpp_discovered_projects` l
WHERE l.source_url IS NOT NULL AND l.source_url <> '';

SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN match_grade='A' THEN 1 ELSE 0 END) AS grade_a,
    SUM(CASE WHEN match_grade='B' THEN 1 ELSE 0 END) AS grade_b,
    SUM(CASE WHEN match_grade='C' THEN 1 ELSE 0 END) AS grade_c,
    SUM(CASE WHEN mine_category='bidding_now' THEN 1 ELSE 0 END) AS bidding_now,
    SUM(CASE WHEN mine_category='early_gold'  THEN 1 ELSE 0 END) AS early_gold
FROM `wdpp_discovered_projects`;
