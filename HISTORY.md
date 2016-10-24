# qe_beaker-abs_bump_and_tag_master - History
## Tags
* [LATEST - 24 Oct, 2016 (4c14d730)](#LATEST)
* [0.1.3 - 16 Sep, 2016 (6f1ced08)](#0.1.3)
* [0.1.2 - 16 Sep, 2016 (b914ae60)](#0.1.2)
* [0.1.1 - 16 Sep, 2016 (10ee39cf)](#0.1.1)

## Details
### <a name = "LATEST">LATEST - 24 Oct, 2016 (4c14d730)

* (GEM) update beaker-abs version to 0.2.0 (4c14d730)

* Merge pull request #5 from puppetlabs/beaker3-conflict (54001ff7)


```
Merge pull request #5 from puppetlabs/beaker3-conflict

(QENG-4472) Relax version constraints
```
* (QENG-4472) Relax version constraints (574d1d95)


```
(QENG-4472) Relax version constraints

Previously, we were pessimistically pinned to beaker 2.x, which meant
projects could not use both beaker 3 and beaker-abs simultaneously.

Beaker-abs only requires a version of beaker supporting the custom
hypervisor API. Due to a beaker bug, custom hypervisors did not work
until beaker 2.9.0 in commit d45e723cd. We also require less than beaker
4 to prevent future incompatibilities.
```
* (MAINT) Update Development notes on releasing (80972ba9)

* Merge pull request #4 from puppetlabs/update-dev-section-in-readme (9f4acbe1)


```
Merge pull request #4 from puppetlabs/update-dev-section-in-readme

(MAINT) Update Development notes on releasing
```
### <a name = "0.1.3">0.1.3 - 16 Sep, 2016 (6f1ced08)

* (HISTORY) update beaker-abs history for gem release 0.1.3 (6f1ced08)

* (GEM) update beaker-abs version to 0.1.3 (3d6ed7b7)

* Merge pull request #3 from puppetlabs/drop-gem-publish-restrictions (c0c786a4)


```
Merge pull request #3 from puppetlabs/drop-gem-publish-restrictions

(maint) Stop restricting where we can push this gem
```
* (maint) Stop restricting where we can push this gem (ba107b81)


```
(maint) Stop restricting where we can push this gem

We want this gem to be public, and this restriction is actually getting
in the way on some of our jenkins instances, and not providing any value.
```
### <a name = "0.1.2">0.1.2 - 16 Sep, 2016 (b914ae60)

* (HISTORY) update beaker-abs history for gem release 0.1.2 (b914ae60)

* (GEM) update beaker-abs version to 0.1.2 (b0ee39d0)

### <a name = "0.1.1">0.1.1 - 16 Sep, 2016 (10ee39cf)

* Initial release.
