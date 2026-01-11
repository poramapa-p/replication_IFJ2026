clear; clc; close all;

%% ---------- Common parameters ----------
mu  = 0.1;          % prior on "w" state
eb  = 0.05;         % expected payoff in "b" state
sdb = 0.02;         % std dev in "b" state
sdw = sdb;          % std dev in "w" state

% helper (define once)
normpdf_local = @(y, m, s) (1./(s*sqrt(2*pi))) .* exp(-0.5*((y - m)./s).^2);

%% ---------- 1) AMBIGUITY FIGURE: vary a, compare gamma ----------
a_grid  = 0.000:0.001:0.15;      % ambiguity levels
gammas  = [0 0.5 1];           % ambiguity aversion
nu_fix  = 0;                     % hold risk aversion fixed

% storage
nA = numel(a_grid); G = numel(gammas);
pwA = zeros(G, nA); eyA = zeros(G, nA); sdA = zeros(G, nA);

% constructs that depend on a (risk "r" kept at 0 here)
r = 0;
sdw1 = sdw + r; 
sdb1 = sdb + r;
ew_base = eb - a_grid;           % ew falls with ambiguity

for i = 1:G
    gamma = gammas(i);
    ew1 = ew_base - nu_fix.*sdw1.^2; % vector
    eb1 = eb      - nu_fix.*sdb1.^2; % scalar

    num = exp(-gamma.*ew1*100);
    den = mu.*num + (1-mu).*exp(-gamma.*eb1*100);
    xi  = num ./ den;

    pwA(i,:) = xi.*mu;
    eyA(i,:) = pwA(i,:).*ew1 + (1 - pwA(i,:)).*eb1;
    sdA(i,:) = sqrt( pwA(i,:).*(sdw1.^2 + (eyA(i,:)-ew1).^2) ...
                   + (1 - pwA(i,:)).*(sdb1.^2 + (eyA(i,:)-eb1).^2) );
end

% --- plot ambiguity figure (4 panels, last = PDFs at selected a) ---
x = a_grid;
legA = {'Ambiguity neutral','Low ambiguity averse','High ambiguity averse'};

% choose which gamma's distributions to display and which a's
gamma_index_for_pdf = 2;                 % 1=0, 2=0.5, 3=1
a_vals_to_show      = [0.05 0.15];  % ambiguity points to compare
a_idx = arrayfun(@(av) find(abs(a_grid - av) == min(abs(a_grid - av)), 1), a_vals_to_show);
mu_sel_A = eyA(gamma_index_for_pdf, a_idx);
sd_sel_A = sdA(gamma_index_for_pdf, a_idx);
y_min_A = min(mu_sel_A - 4*sd_sel_A);
y_max_A = max(mu_sel_A + 4*sd_sel_A);
y_grid_A = linspace(y_min_A, y_max_A, 400);

figA = builtin('figure','Position',[50 50 520 820]);   % taller for 4 panels
tiledlayout(3,1,'TileSpacing','tight');

% Panel 1: P(w)
nexttile
plot(x,pwA(1,:),'-', x,pwA(2,:),'--', x,pwA(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
ylabel('$P(w)$','Interpreter','latex');
xlim([x(1) x(end)]); ylim([0 1]);

% Panel 2: E(Y)
nexttile
plot(x,eyA(1,:),'-', x,eyA(2,:),'--', x,eyA(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
ylabel('$E(Y)$','Interpreter','latex');
xlim([x(1) x(end)]);

% Panel 3: sigma(Y)
nexttile
plot(x,sdA(1,:),'-', x,sdA(2,:),'--', x,sdA(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
xlabel('Ambiguity'); ylabel('$\sigma(Y)$','Interpreter','latex');
xlim([x(1) x(end)]);
legend(legA,'Interpreter','latex','Location','southoutside','NumColumns',2,'FontSize',14);


figA.PaperPositionMode = 'auto';
exportgraphics(figA, 'ambiguity_figure.png', 'Resolution', 300);
%% ---------- 2) RISK FIGURE: vary r, compare nu ----------
r_grid = 0:0.001:0.15;           % risk add-on (to std devs)
nus    = [0 0.5 1.0];            % risk aversion
gamma_fix = 0;                 % hold ambiguity aversion fixed
a_const = 0.075;                  % so ew = eb - a_const
ew_const = eb - a_const;

% storage
nR = numel(r_grid); N = numel(nus);
pwR = zeros(N, nR); eyR = zeros(N, nR); sdR = zeros(N, nR);

for i = 1:N
    nu = nus(i);

    sdw1 = sdw + r_grid;         % vector over r
    sdb1 = sdb + r_grid;

    ew1 = ew_const - 2*nu.*(sdw1.^2);   % vector
    eb1 = eb        - 2*nu.*(sdb1.^2);  % vector (depends on r as well)

    num = exp(-gamma_fix.*ew1*100);
    den = mu.*num + (1-mu).*exp(-gamma_fix.*eb1*100);
    xi  = num ./ den;

    pwR(i,:) = xi.*mu;
    eyR(i,:) = pwR(i,:).*ew1 + (1 - pwR(i,:)).*eb1;
    sdR(i,:) = sqrt( pwR(i,:).*(sdw1.^2 + (eyR(i,:)-ew1).^2) ...
                   + (1 - pwR(i,:)).*(sdb1.^2 + (eyR(i,:)-eb1).^2) );
end

% --- plot risk figure (4 panels, last = PDFs at selected r) ---
x = r_grid;
legR = {'Risk neutral','Low risk averse','High risk averse'};

% choose which nu's distributions to display and which r's
nu_index_for_pdf = 2;                % 1=0, 2=0.5, 3=1.0
r_vals_to_show   = [0.05 0.15]; % risk points to compare
r_idx = arrayfun(@(rv) find(abs(r_grid - rv) == min(abs(r_grid - rv)), 1), r_vals_to_show);
mu_sel_R = eyR(nu_index_for_pdf, r_idx);
sd_sel_R = sdR(nu_index_for_pdf, r_idx);
y_min_R = min(mu_sel_R - 4*sd_sel_R);
y_max_R = max(mu_sel_R + 4*sd_sel_R);
y_grid_R = linspace(y_min_R, y_max_R, 400);

figR =builtin('figure','Position',[50 50 520 820]);  % taller for 4 panels
tiledlayout(3,1,'TileSpacing','tight');

% Panel 1: P(w)
nexttile
plot(x,pwR(1,:),'-', x,pwR(2,:),'--', x,pwR(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
xlabel('Risk'); ylabel('$P(w)$','Interpreter','latex');
xlim([x(1) x(end)]); ylim([0 1]);

% Panel 2: E(Y)
nexttile
plot(x,eyR(1,:),'-', x,eyR(2,:),'--', x,eyR(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
xlabel('Risk'); ylabel('$E(Y)$','Interpreter','latex');
xlim([x(1) x(end)]);

% Panel 3: sigma(Y)
nexttile
plot(x,sdR(1,:),'-', x,sdR(2,:),'--', x,sdR(3,:),':', 'LineWidth',1.5);
set(gca,'FontSize',12,'FontName','Times New Roman');
xlabel('Risk'); ylabel('$\sigma(Y)$','Interpreter','latex');
xlim([x(1) x(end)]);
legend(legR,'Interpreter','latex','Location','southoutside','NumColumns',2,'FontSize',14);

% Panel 4: PDFs at selected r
% nexttile; hold on
% for k = 1:numel(r_idx)
%     pdf_k = normpdf_local(y_grid_R, mu_sel_R(k), sd_sel_R(k));
%     plot(y_grid_R, pdf_k, 'LineWidth', 1.5, ...
%         'DisplayName', sprintf('r = %.2f, \\nu = %.1f', r_vals_to_show(k), nus(nu_index_for_pdf)));
% end
% set(gca,'FontSize',10,'FontName','Times New Roman');
% xlabel('Y'); ylabel('PDF');
% title(sprintf('Distributions at selected r, \\nu = %.1f', nus(nu_index_for_pdf)), 'Interpreter','latex');
% legend('Location','best'); box on; hold off;

figR.PaperPositionMode = 'auto';
exportgraphics(figR, 'risk_figure.png', 'Resolution', 300);